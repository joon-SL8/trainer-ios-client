import Foundation
import Combine
import libfitness

class CalendarViewModel: ObservableObject {
    @Published var session: libfitness.Session
    @Published var workout: MRCWorkout?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init(session: libfitness.Session) {
        self.session = session
        loadWorkout()
    }

    private func loadWorkout() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var url: URL?
            
            // Bypass check for mock sessions
            if self.session.name == "Mock Session" {
                do {
                    url = try MRCParser.getRandomMRCFile()
                } catch {
                    print("Failed to get random MRC file for mock session: \(error)")
                }
            } else if !self.session.mrcFilepath.isEmpty {
                url = URL(fileURLWithPath: self.session.mrcFilepath)
            }
            
            // Try random file if path is still empty or file not found
            if url == nil {
                do {
                    url = try MRCParser.getRandomMRCFile()
                } catch {
                    print("Failed to get random MRC file: \(error)")
                }
            }
            
            guard let fileUrl = url else {
                DispatchQueue.main.async {
                    self.errorMessage = "No workout file available."
                    self.isLoading = false
                }
                return
            }
            
            do {
                let workout = try MRCParser.parse(fileUrl: fileUrl)
                
                DispatchQueue.main.async {
                    self.workout = workout
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to parse MRC file: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
