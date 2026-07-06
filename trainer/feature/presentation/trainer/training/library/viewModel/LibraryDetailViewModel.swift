import Foundation
import SwiftUI
import Combine
import libfitness

class LibraryDetailViewModel: ObservableObject {
    @Published var course: MrcCourse? = nil
    @Published var workout: MRCWorkout? = nil
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil
    @Published var isBookmarked: Bool = false
    @Published var tss: Double = 0.0
    @Published var np: Double = 0.0
    @Published var ftp: Double = 0.0

    func loadWorkout(_ workout: MRCWorkout, filename: String) {
        self.workout = workout
        self.course = MRCCourseMapper.map(workout: workout)
        self.isLoading = false
        calculateMetrics()
        checkBookmarkStatus(filename: filename)
    }

    func parseFile(named fileName: String) {
        isLoading = true
        errorMessage = nil

        do {
            guard let url = try MRCParser.findMRCFile(named: fileName) else {
                errorMessage = "File not found."
                isLoading = false
                return
            }

            let content = try String(contentsOf: url, encoding: .utf8)
            if content.isEmpty {
                errorMessage = "File is empty or corrupted."
                isLoading = false
                return
            }

            let lines = content.components(separatedBy: .newlines)
            let parser = AssetFileParseUseCase(file: fileName, lines: lines)
            self.course = parser.invoke()
            if let course = self.course {
                self.workout = MRCWorkout(from: course)
                calculateMetrics()
            } else {
                errorMessage = "Failed to parse file content."
            }
        } catch {
            errorMessage = "File error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func checkBookmarkStatus(filename: String) {
        let bookmarkedPaths = UserDefaults.standard.stringArray(forKey: "bookmarked_assets") ?? []
        isBookmarked = bookmarkedPaths.contains(filename)
    }

    func toggleBookmark(filename: String) {
        var bookmarkedPaths = UserDefaults.standard.stringArray(forKey: "bookmarked_assets") ?? []
        
        if isBookmarked {
            bookmarkedPaths.removeAll { $0 == filename }
        } else {
            bookmarkedPaths.append(filename)
        }
        
        UserDefaults.standard.set(bookmarkedPaths, forKey: "bookmarked_assets")
        isBookmarked.toggle()
    }

    private func calculateMetrics() {
        guard let workout = self.workout else { return }

        Task {
            let analysis = Analysis()
            do {
                try await analysis.initialize()
                DispatchQueue.main.async {
                    self.ftp = analysis.ftp
                }
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

                let npValue = analysis.normalizedPower(power: powerValues)
                let tssValue = analysis.calculateTssForPowerList(powers: powerValues, durationSeconds: Int64(totalDuration))

                DispatchQueue.main.async {
                    self.tss = tssValue
                    self.np = npValue
                }
            } catch {
                print("Error calculating metrics: \(error)")
            }
        }
    }
}
