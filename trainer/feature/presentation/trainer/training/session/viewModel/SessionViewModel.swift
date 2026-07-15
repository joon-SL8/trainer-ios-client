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

    // History for histograms
    public private(set) var powerHistory: [Double] = []
    public private(set) var heartRateHistory: [Double] = []
    public private(set) var cadenceHistory: [Double] = []
    public private(set) var speedHistory: [Double] = []

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
    
    @Published public var ftp: Double = 1.0
    
    @Published public var isPedaling: Bool = false
    private var lowPowerStartTime: Date?
    private let lowPowerDuration: TimeInterval = 5.0
    private let powerThreshold: Double = 15.0
    
    // Thresholds
    private var powerMatchStartTime: Date?
    private var pauseStartTime: Date?
    private let matchDuration: TimeInterval = 3.0
    private let pauseDuration: TimeInterval = 5.0
    private let powerTolerance: Double = 5.0 // +/- 5 Watts

    private func monitorPedalingForModal() {
        guard state == .completed else { return }
        
        let currentPower = power ?? 0
        
        if currentPower < powerThreshold {
            if lowPowerStartTime == nil {
                lowPowerStartTime = Date()
            } else if let startTime = lowPowerStartTime, Date().timeIntervalSince(startTime) >= lowPowerDuration {
                showSummaryModal = true
                lowPowerStartTime = nil // Reset
            }
        } else {
            lowPowerStartTime = nil
        }
    }

    public init(sensors: [MockSensor] = [], workout: MRCWorkout? = nil, mrcFilePath: String? = nil, bluetoothManager: BluetoothManager) {
        self.workout = workout
        self.mrcFilePath = mrcFilePath
        self.orchestrator = SessionOrchestrator(bluetoothManager: bluetoothManager)
        
        // Fetch threshold from profile
        let getProfileUseCase = GetCustomProfileUseCase()
        if let ftpString = getProfileUseCase.invoke(key: "PROFILE_KEY_FTP") {
            self.ftp = Double(ftpString) ?? 1.0
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
                guard let self = self else { return }
                guard let newPacket = newPacket else { return }
                
                self.power = Double(newPacket.powerLevel)
                self.isPowerConnected = true
                
                self.handlePowerLogic()
                
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
                self.monitorPedalingForModal()
            }
            .store(in: &cancellables)
            
        startObservingTimer()
    }
    
    private func handlePowerLogic() {
        guard let currentPower = self.power else { return }
        let now = Date()
        
        // Logic for Start/Resume
        if let target = targetPower, abs(currentPower - target) <= powerTolerance {
            pauseStartTime = nil // Reset pause timer if power matches target
            if powerMatchStartTime == nil {
                powerMatchStartTime = now
            } else if let startTime = powerMatchStartTime, now.timeIntervalSince(startTime) >= matchDuration {
                if state == .idle {
                    startSession()
                } else if state == .paused {
                    resumeSession()
                }
                powerMatchStartTime = nil // Reset after action
            }
        } else {
            powerMatchStartTime = nil // Reset if power doesn't match
        }
        
        // Logic for Pause
        if state == .active {
            if currentPower <= 0 { // Assuming low/zero power means "not pedaling" or pause
                if pauseStartTime == nil {
                    pauseStartTime = now
                } else if let startTime = pauseStartTime, now.timeIntervalSince(startTime) >= pauseDuration {
                    pauseSession()
                    pauseStartTime = nil // Reset after action
                }
            } else {
                pauseStartTime = nil // Reset if power is not low/zero
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
        
        // Check for session completion
        if let lastBlock = workout.blocks.last, (elapsedTime / 60.0) >= lastBlock.endTime {
            completeSession()
            return
        }

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
    
    public func completeSession() {
        state = .completed
        metricsTimerTask?.cancel()
        metricsTimerTask = nil
        showSummaryModal = true
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
        
        let currentPower = power ?? 0
        let currentHeartRate = heartRate ?? 0
        let currentSpeed = speed ?? 0
        let currentCadence = cadence ?? 0

        // Append to history
        powerHistory.append(currentPower)
        heartRateHistory.append(currentHeartRate)
        cadenceHistory.append(currentCadence)
        speedHistory.append(currentSpeed)

        // Collect metrics
        let entry = libfitness.SessionEntry(id: 0, session: sessionId, name: "", description: "", start: "", duration: Int64(elapsedTime), power: Int64(currentPower), heart: Int64(currentHeartRate), speed: Int64(currentSpeed), cadence: Int64(currentCadence))
        
        UpdateSessionEntryUseCase().invoke(entry: entry)
    }
    
    public func calculateSessionMetrics() -> (avgPower: Double, np: Double, ifFactor: Double, tss: Double, powerValues: [Double]) {
        let avgPower = powerHistory.isEmpty ? 0 : powerHistory.reduce(0, +) / Double(powerHistory.count)
        // NP, IF, TSS calculations would be more complex, keeping placeholders for now as per original
        return (avgPower, 180.0, 0.75, 45.0, powerHistory)
    }
    
    public func requestControl() {
        orchestrator.requestControl()
    }
    
    public func pauseSession() {
        orchestrator.pauseSession()
        state = .paused
    }
    
    public func resumeSession() {
        orchestrator.resumeSession()
        state = .active
    }
    
    public func pauseTimerObservation() {
        timerTask?.cancel()
        timerTask = nil
    }

    public func resumeTimerObservation() {
        startObservingTimer()
    }
    
    public func continueSession() {
        showSummaryModal = false
    }
    
    public func exitSession() {
        orchestrator.stopSession()
        state = .idle
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
