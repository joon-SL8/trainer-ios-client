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
    
    @Published public var isHRConnected: Bool = false
    @Published public var isPowerConnected: Bool = false
    @Published public var isCadenceConnected: Bool = false

    public var currentBlockZoneColor: Color {
        guard let workout = workout else { return .blue }
        let currentMinutes = elapsedTime / 60.0
        if let currentBlock = workout.blocks.first(where: { currentMinutes >= $0.startTime && currentMinutes < $0.endTime }) {
            let percentage = Int(currentBlock.targetPower * intensityFactor)
            return PowerZoneDefinition.zone(forPowerPercentage: percentage).swiftColor
        }
        return .blue
    }
    
    public init(sensors: [MockSensor] = [], workout: MRCWorkout? = nil, bluetoothManager: BluetoothManager) {
        self.workout = workout
        self.orchestrator = SessionOrchestrator(bluetoothManager: bluetoothManager)
        
        // Listen to orchestrator for connectivity updates (if needed, or map initial state)
        orchestrator.$currentHeartRateContent
            .receive(on: RunLoop.main)
            .sink { [weak self] newContent in
                self?.currentHeartRateContent = newContent
                self?.heartRate = newContent?.content.hrData != nil ? Double(newContent!.content.hrData) : nil // Update heartRate from newContent
            }
            .store(in: &cancellables)
    }
    
    public func startSession() {
        guard let workout = workout else { return }
        orchestrator.startSession(with: workout)
        state = .active
    }
    
    public func pauseSession() {
        orchestrator.pauseSession()
        state = .paused
    }
    
    public func stopSession() {
        orchestrator.stopSession()
        state = .idle
        elapsedTime = 0
    }
    
    public var formattedBlockProgress: String {
        guard let elapsed = currentBlockElapsedTime, let total = currentBlockTotalTime else {
            return "--:-- / --:--"
        }
        return "\(formatTimeInterval(elapsed)) / \(formatTimeInterval(total))"
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

}
