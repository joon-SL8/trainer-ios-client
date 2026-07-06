import Foundation
import Combine
import SwiftUI

import Foundation
import Combine
import SwiftUI
import libfitness

public class SessionViewModel: ObservableObject {
    @Published public var state: SessionState = .idle
    @Published public var workout: MRCWorkout?
    @Published public var elapsedTime: TimeInterval = 0
    @Published public var intensityFactor: Double = 1.0 
    
    // Live metrics from sensors
    @Published public var heartRate: Double?
    @Published public var power: Double?
    @Published public var cadence: Double?
    @Published public var speed: Double?

    @Published public var currentHeartRateContent: HeartRateContent? // Add this published property
    
    // Target metrics
    @Published public var targetPower: Double?
    @Published public var currentBlockElapsedTime: TimeInterval?
    @Published public var currentBlockTotalTime: TimeInterval?
    
    private let orchestrator: SessionOrchestrator
    private var cancellables = Set<AnyCancellable>()
    private var timerTask: Task<Void, Never>?
    
    @Published public var isHRConnected: Bool = false
    @Published public var isPowerConnected: Bool = false
    @Published public var isCadenceConnected: Bool = false
    @Published public var showSummaryModal: Bool = false
    
    public let mrcFilePath: String?
    
    // Last CP packet for calculations
    private var lastCyclingPowerMeasurementPacket: CyclingPowerMeasurementPacket?
    
    private var currentSessionId: Int64?
    private var metricsTimerTask: Task<Void, Never>?

    public var currentBlockZoneColor: Color {
        guard let workout = workout else { return .blue }
        let currentMinutes = elapsedTime / 60.0
        if let currentBlock = workout.blocks.first(where: { currentMinutes >= $0.startTime && currentMinutes < $0.endTime }) {
            let averagePower = (currentBlock.targetStartPower + currentBlock.targetEndPower) / 2.0
            let percentage = Int(averagePower * intensityFactor)
            return PowerZoneDefinition.zone(forPowerPercentage: percentage).swiftColor
        }
        return .blue
    }
    
    // Thresholds
    private var powerAboveThresholdStartTime: Date?
    private var powerBelowThresholdStartTime: Date?
    private let thresholdPower: Double = 20.0
    private let thresholdDuration: TimeInterval

    public init(sensors: [MockSensor] = [], workout: MRCWorkout? = nil, mrcFilePath: String? = nil, bluetoothManager: BluetoothManager) {
        self.workout = workout
        self.mrcFilePath = mrcFilePath
        self.orchestrator = SessionOrchestrator(bluetoothManager: bluetoothManager)
        
        // Fetch threshold from profile
        let getProfileUseCase = GetCustomProfileUseCase()
        if let thresholdString = getProfileUseCase.invoke(key: "detect_pause"),
           let duration = Double(thresholdString) {
            self.thresholdDuration = duration
        } else {
            self.thresholdDuration = 20.0 // Default 20 seconds
        }
        
        // Listen to orchestrator for connectivity updates (if needed, or map initial state)
        orchestrator.$currentHeartRateContent
            .receive(on: RunLoop.main)
            .sink { [weak self] newContent in
                self?.currentHeartRateContent = newContent
                self?.heartRate = newContent?.content.hrData != nil ? Double(newContent!.content.hrData) : nil // Update heartRate from newContent
            }
            .store(in: &cancellables)
            
        // Subscribe to Cycling Power updates
        orchestrator.$cyclingPowerPacket
            .receive(on: RunLoop.main)
            .sink { [weak self] newPacket in
                guard let self = self, let newPacket = newPacket else { return }
                
                self.power = Double(newPacket.powerLevel)
                self.isPowerConnected = true
                
                self.handlePowerThresholdLogic()
                
                if let lastPacket = self.lastCyclingPowerMeasurementPacket {
                    // Calculate RPM and Speed based on newPacket and lastPacket
                    let rpm = CyclingPowerMeasurementPacket.companion.calculateRPM(current: newPacket, previous: lastPacket)
                    self.cadence = Double(rpm)
                    
                    if let speed = CyclingPowerMeasurementPacket.companion.calculateSpeed(current: newPacket, previous: lastPacket) {
                        self.speed = Double(truncating: speed)
                    }
                    self.isCadenceConnected = true
                }
                
                self.lastCyclingPowerMeasurementPacket = newPacket
            }
            .store(in: &cancellables)
            
        startObservingTimer()
    }
    
    private func handlePowerThresholdLogic() {
        guard let power = self.power else { return }
        let now = Date()
        
        if power >= thresholdPower {
            powerBelowThresholdStartTime = nil
            if powerAboveThresholdStartTime == nil {
                powerAboveThresholdStartTime = now
            } else if let startTime = powerAboveThresholdStartTime, now.timeIntervalSince(startTime) >= thresholdDuration {
                if state == .idle || state == .paused {
                    startSession()
                }
            }
        } else {
            powerAboveThresholdStartTime = nil
            if powerBelowThresholdStartTime == nil {
                powerBelowThresholdStartTime = now
            } else if let startTime = powerBelowThresholdStartTime, now.timeIntervalSince(startTime) >= thresholdDuration {
                if state == .active {
                    pauseSession()
                }
            }
        }
    }
    
    private func startObservingTimer() {
        timerTask = Task {
            for await time in orchestrator.timer.asTimestampProvider {
                await MainActor.run {
                    self.elapsedTime = Double(time) / 1000.0
                    updateBlockProgress()
                }
            }
        }
    }
    
    private func updateBlockProgress() {
        guard let workout = workout else { return }
        let currentMinutes = elapsedTime / 60.0
        if let currentBlock = workout.blocks.first(where: { currentMinutes >= $0.startTime && currentMinutes < $0.endTime }) {
            self.currentBlockElapsedTime = (currentMinutes - currentBlock.startTime) * 60.0
            self.currentBlockTotalTime = (currentBlock.endTime - currentBlock.startTime) * 60.0
            
            // Calculate and set target power
            // Formula: (PowerPercentage/100) * IntensityFactor * FTP
            let averagePowerPercentage = (currentBlock.targetStartPower + currentBlock.targetEndPower) / 2.0
            
            let getProfileUseCase = GetCustomProfileUseCase()
            let ftpString = getProfileUseCase.invoke(key: "PROFILE_KEY_FTP")
            let ftp = Double(ftpString ?? "") ?? 100.0
            
            let targetPower = Int((averagePowerPercentage / 100.0) * intensityFactor * ftp)
            
            self.targetPower = Double(targetPower)
            orchestrator.updateTargetPower(power: targetPower)
            
            objectWillChange.send()
        }
    }
    
    public func startSession() {
        guard let workout = workout else { return }
        // Map MRCWorkout to MrcCourse
        let mrcCourse = MRCCourseMapper.map(workout: workout)
        orchestrator.setCourseData(course: mrcCourse)
        orchestrator.startSession(with: workout)
        state = .active
        
        // Persist Session
        let session = libfitness.Session(id: 0, name: workout.name, description: "", sessionDate: Int64(Date().timeIntervalSince1970 * 1000), duration: 0, mrcFilename: "", mrcFilepath: mrcFilePath ?? "", sessionFilename: "")
        self.currentSessionId = UpdateSessionUseCase().invoke(session: session)
        
        // Start periodic metrics recording
        startMetricsRecording()
    }
    
    private func startMetricsRecording() {
        metricsTimerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await recordMetrics()
            }
        }
    }
    
    private func recordMetrics() async {
        guard let sessionId = currentSessionId else { return }
        
        // Collect metrics
        let entry = libfitness.SessionEntry(id: 0, session: sessionId, name: "", description: "", start: "", duration: Int64(elapsedTime), power: Int64(power ?? 0), heart: Int64(heartRate ?? 0), speed: Int64(speed ?? 0), cadence: Int64(cadence ?? 0))
        
        UpdateSessionEntryUseCase().invoke(entry: entry)
    }
    
    public func calculateSessionMetrics() -> (avgPower: Double, np: Double, ifFactor: Double, tss: Double, powerValues: [Double]) {
        // Placeholder implementation
        return (150.0, 180.0, 0.75, 45.0, [100.0, 150.0, 200.0, 150.0, 100.0])
    }
    
    public func pauseSession() {
        orchestrator.pauseSession()
        state = .paused
    }
    
    public func stopSession() {
        orchestrator.stopSession()
        state = .idle
        elapsedTime = 0
        currentSessionId = nil
        metricsTimerTask?.cancel()
    }
    
    public var formattedBlockProgress: String {
        guard let elapsed = currentBlockElapsedTime, let total = currentBlockTotalTime else {
            return "--:-- / --:--"
        }
        let remaining = max(0, total - elapsed)
        return formatTimeInterval(remaining)
    }
    
    public var blockProgressPercentage: Double {
        guard let elapsed = currentBlockElapsedTime, let total = currentBlockTotalTime, total > 0 else {
            return 0
        }
        return min(1.0, max(0.0, elapsed / total))
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        print("SessionViewModel: Cleaning up...")
        orchestrator.cleanup()
    }

}
