import Foundation
import SwiftUI
import Combine
import libfitness

class RandomSessionViewModel: ObservableObject {
    @Published var workout: MRCWorkout?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    init() {
        fetchRandomWorkout()
    }
    
    func calculateEstimatedTSS(workout: MRCWorkout) async -> Double {
        let analysis = Analysis()
        do {
            try await analysis.initialize()
            var powerValues: [KotlinDouble] = []
            var totalDuration: Double = 0

            for block in workout.blocks {
                let durationSeconds = Int((block.endTime - block.startTime) * 60)
                totalDuration += Double(durationSeconds)
                let avgPercentage = (block.targetStartPower + block.targetEndPower) / 2.0
                let targetPower = (avgPercentage / 100.0) * analysis.ftp
                for _ in 0..<durationSeconds {
                    powerValues.append(KotlinDouble(value: targetPower))
                }
            }

            return analysis.calculateTssForPowerList(powers: powerValues, durationSeconds: Int64(totalDuration))
        } catch {
            print("Error calculating TSS: \(error)")
            return 0.0
        }
    }

    func fetchRandomWorkout() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                if let fileURL = try MRCParser.getRandomMRCFile() {
                    let parsedWorkout = try MRCParser.parse(fileUrl: fileURL)
                    self.workout = parsedWorkout
                } else {
                    self.errorMessage = "No workout found."
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}
