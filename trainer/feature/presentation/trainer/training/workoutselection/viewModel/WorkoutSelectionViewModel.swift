import Foundation
import Combine
import SwiftUI

class WorkoutSelectionViewModel: ObservableObject {
    @Published var selectedWorkout: String?
    @Published var workout: MRCWorkout?
    @Published var showSensorSelection: Bool = false
    @Published var workoutSelectionError: String? = nil
    @Published var showLibrary: Bool = false
    
    func selectTodaysWorkout() {
        print("WorkoutSelectionViewModel: Attempting to select today's workout.")
        if let fileURL = try? MRCParser.findMRCFile(named: "w01d1-ramptest_tr.mrc") {
            print("WorkoutSelectionViewModel: Found fileURL for w01d1-ramptest_tr.mrc: \(fileURL.lastPathComponent)")
            if let parsedWorkout = try? MRCParser.parse(fileUrl: fileURL) {
                print("WorkoutSelectionViewModel: Successfully parsed w01d1-ramptest_tr.mrc.")
                self.workout = parsedWorkout
                self.selectedWorkout = fileURL.lastPathComponent
                self.showSensorSelection = true
                print("WorkoutSelectionViewModel: Selected Today's Workout: \(fileURL.lastPathComponent). showSensorSelection = true")
                return
            } else {
                print("WorkoutSelectionViewModel: Failed to parse w01d1-ramptest_tr.mrc from URL: \(fileURL.lastPathComponent)")
                self.workoutSelectionError = "Unable to open the selected workout file."
            }
        } else {
            print("WorkoutSelectionViewModel: Failed to find fileURL for w01d1-ramptest_tr.mrc.")
            self.workoutSelectionError = "Unable to open the selected workout file."
        }
        
        // Fallback to training-3min.mrc if default is not found or parsing fails
        print("WorkoutSelectionViewModel: Attempting fallback to training-3min.mrc.")
        if let fallbackURL = try? MRCParser.findMRCFile(named: "training-3min.mrc") {
            print("WorkoutSelectionViewModel: Found fallbackURL for training-3min.mrc: \(fallbackURL.lastPathComponent)")
            if let parsedWorkout = try? MRCParser.parse(fileUrl: fallbackURL) {
                print("WorkoutSelectionViewModel: Successfully parsed training-3min.mrc.")
                self.workout = parsedWorkout
                self.selectedWorkout = fallbackURL.lastPathComponent
                self.showSensorSelection = true
                print("WorkoutSelectionViewModel: Fallback to training-3min.mrc: \(fallbackURL.lastPathComponent). showSensorSelection = true")
                return
            } else {
                print("WorkoutSelectionViewModel: Failed to parse training-3min.mrc from URL: \(fallbackURL.lastPathComponent)")
                self.workoutSelectionError = "Unable to open the selected workout file."
            }
        } else {
            print("WorkoutSelectionViewModel: Failed to find fallbackURL for training-3min.mrc.")
            self.workoutSelectionError = "Unable to open the selected workout file."
        }
        
        print("WorkoutSelectionViewModel: Error - No default or fallback workout file could be loaded.")
        // Optionally, handle error state, e.g., show an alert
    }
    
    func chooseFromLibrary() {
        showLibrary = true
    }
    
    func reset() {
        self.showSensorSelection = false
        self.showLibrary = false
        self.workoutSelectionError = nil
        print("WorkoutSelectionViewModel: State reset.")
    }
}