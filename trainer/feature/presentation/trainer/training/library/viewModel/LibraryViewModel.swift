import Foundation
import libfitness
import Combine

class LibraryViewModel: ObservableObject {
    @Published var items: [AssetProperty] = []
    @Published var pathStack: [String] = [""] // Starts with root
    @Published var errorMessage: String? = nil
    
    // Parsing state
    @Published var isParsing: Bool = false
    @Published var parsingProgress: Double = 0.0
    @Published var parsingError: String? = nil
    @Published var parsedWorkout: MRCWorkout? = nil
    
    private var parsingTask: Task<Void, Never>?
    private let pathProvider = AssetPathProviderUseCase()
    
    init() {
        fetchItems()
    }
    
    func parseWorkout(file: AssetProperty, directoryPath: String) {
        let fileName = file.data as? String ?? ""
        guard let url = try? MRCParser.findMRCFile(named: fileName) else {
            self.parsingError = "File not found"
            return
        }
        
        cancelParsing()
        isParsing = true
        parsingProgress = 0.0
        parsingError = nil
        parsedWorkout = nil
        
        parsingTask = Task { @MainActor in
            do {
                let workout = try await MRCParser.parseAsync(fileUrl: url) { progress in
                    Task { @MainActor in
                        self.parsingProgress = progress
                    }
                }
                
                if Task.isCancelled { return }
                
                if let workout = workout {
                    self.parsedWorkout = workout
                } else {
                    self.parsingError = "Failed to parse file"
                }
                self.isParsing = false
            } catch is CancellationError {
                // Handled by isCancelled check or just silence
                print("Parsing cancelled")
            } catch {
                if !Task.isCancelled {
                    self.parsingError = error.localizedDescription
                    self.isParsing = false
                }
            }
        }
    }
    
    func cancelParsing() {
        parsingTask?.cancel()
        parsingTask = nil
        isParsing = false
    }
    
    var currentPath: String {
        pathStack.last ?? ""
    }
    
    func fetchItems() {
        let items = pathProvider.invoke(assetFilePath: currentPath)
        if items.isEmpty {
            self.items = []
            // We don't set an error for empty directories, just show empty state
        } else {
            self.items = items
        }
    }
    
    func navigateTo(directory path: String) {
        pathStack.append(path)
        fetchItems()
    }
    
    func navigateBack() {
        if pathStack.count > 1 {
            pathStack.removeLast()
            fetchItems()
        }
    }
    
    func isRoot() -> Bool {
        return pathStack.count <= 1
    }
    
    func itemDisplayName(_ item: AssetProperty) -> String {
        return item.data as? String ?? "Unknown"
    }
}
