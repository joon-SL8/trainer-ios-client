import Foundation

public enum MRCParserError: Error {
    case fileReadError(Error)
    case invalidFileContent(String)
    case fileNotFound(String)
    case parsingError(String)
}

public class MRCParser {
    public static func parse(fileUrl: URL) throws -> MRCWorkout? {
        let content: String
        do {
            content = try String(contentsOf: fileUrl, encoding: .utf8)
        } catch {
            print("Error parsing MRC file at \(fileUrl.lastPathComponent): \(error.localizedDescription)")
            throw MRCParserError.fileReadError(error)
        }
        
        let lines = content.components(separatedBy: .newlines)
        var blocks: [MRCBlock] = []
        var isCourseData = false
        var lineBuffer: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if trimmed == "[COURSE DATA]" {
                isCourseData = true
                continue
            }
            
            if trimmed == "[END COURSE DATA]" {
                isCourseData = false
                break
            }
            
            if isCourseData {
                lineBuffer.append(trimmed)
                if lineBuffer.count == 2 {
                    if let block = parsePair(line1: lineBuffer[0], line2: lineBuffer[1]) {
                        blocks.append(block)
                    } else {
                        let errorMessage = "Failed to parse block from lines: \(lineBuffer[0]), \(lineBuffer[1])"
                        print("Parsing error in MRC file at \(fileUrl.lastPathComponent): \(errorMessage)")
                        throw MRCParserError.parsingError(errorMessage)
                    }
                    lineBuffer.removeAll()
                }
            }
        }
        
        let workoutName = fileUrl.deletingPathExtension().lastPathComponent
        return MRCWorkout(name: workoutName, blocks: blocks)
    }

    public static func parseAsync(
        fileUrl: URL,
        onProgress: @escaping (Double) -> Void
    ) async throws -> MRCWorkout? {
        let content: String
        do {
            content = try String(contentsOf: fileUrl, encoding: .utf8)
        } catch {
            print("Error parsing async MRC file at \(fileUrl.lastPathComponent): \(error.localizedDescription)")
            throw MRCParserError.fileReadError(error)
        }

        let lines = content.components(separatedBy: .newlines)
        let totalLines = Double(lines.count)

        var blocks: [MRCBlock] = []
        var isCourseData = false
        var lineBuffer: [String] = []

        for (index, line) in lines.enumerated() {
            // Check for cancellation
            try Task.checkCancellation()

            // Periodically yield to keep UI responsive and allow cancellation to be processed
            if index % 50 == 0 {
                await Task.yield()
                onProgress(Double(index) / totalLines)
                // Small delay to simulate work if the file is too small,
                // making the progress bar visible in the demo.
                try? await Task.sleep(nanoseconds: 10_000_000) // 0.01s
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed == "[COURSE DATA]" {
                isCourseData = true
                continue
            }

            if trimmed == "[END COURSE DATA]" {
                isCourseData = false
                onProgress(1.0)
                break
            }

            if isCourseData {
                lineBuffer.append(trimmed)
                if lineBuffer.count == 2 {
                    if let block = parsePair(line1: lineBuffer[0], line2: lineBuffer[1]) {
                        blocks.append(block)
                    } else {
                        let errorMessage = "Failed to parse block from lines: \(lineBuffer[0]), \(lineBuffer[1])"
                        print("Parsing error in async MRC file at \(fileUrl.lastPathComponent): \(errorMessage)")
                        throw MRCParserError.parsingError(errorMessage)
                    }
                    lineBuffer.removeAll()
                }
            }
        }

        let workoutName = fileUrl.deletingPathExtension().lastPathComponent
        onProgress(1.0)
        return MRCWorkout(name: workoutName, blocks: blocks)
    }
    
    private static func parsePair(line1: String, line2: String) -> MRCBlock? {
        // Use character set for both tabs and spaces
        let parts1 = line1.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let parts2 = line2.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard parts1.count >= 2, parts2.count >= 2 else { return nil }
        
        guard let startPower = Double(parts1[1].replacingOccurrences(of: ",", with: ".")),
              let startMinutes = Double(parts1[0].replacingOccurrences(of: ",", with: ".")),
              let endPower = Double(parts2[1].replacingOccurrences(of: ",", with: ".")),
              let endMinutes = Double(parts2[0].replacingOccurrences(of: ",", with: ".")) else { return nil }
        
        return MRCBlock(startTime: startMinutes, endTime: endMinutes, targetStartPower: startPower, targetEndPower: endPower)
    }
    
    public static func getRandomMRCFile() throws -> URL? {
        let frameworkBundle = Bundle(identifier: "com.skjline.fitness.libfitness")
        let trainingSubPath = "composeResources/com.skjline.fitness.resources/files/training"
        
        var mrcFiles: [URL] = []
        
        // First, try to find in the framework bundle
        if let bundleURL = frameworkBundle?.resourceURL?.appendingPathComponent(trainingSubPath) {
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
            
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == "mrc" {
                    mrcFiles.append(fileURL)
                }
            }
        }
        
        // If no files found in framework bundle, try main app bundle
        if mrcFiles.isEmpty, let mainBundleURL = Bundle.main.resourceURL {
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(at: mainBundleURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
            
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == "mrc" {
                    mrcFiles.append(fileURL)
                }
            }
        }
        
        guard let randomFile = mrcFiles.randomElement() else {
            let errorMessage = "No random MRC file could be found in framework or main app bundle."
            print("File Not Found: \(errorMessage)")
            throw MRCParserError.fileNotFound(errorMessage)
        }
        
        return randomFile
    }
    
    public static func findMRCFile(named: String) throws -> URL? {
        let frameworkBundle = Bundle(identifier: "com.skjline.fitness.libfitness")
        let trainingSubPath = "composeResources/com.skjline.fitness.resources/files/training"
        
        let fileManager = FileManager.default
        let searchDirectories = [
            frameworkBundle?.resourceURL?.appendingPathComponent(trainingSubPath),
            Bundle.main.resourceURL
        ].compactMap { $0 }
        
        for searchDir in searchDirectories {
            let enumerator = fileManager.enumerator(at: searchDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])
            
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.lastPathComponent == named || fileURL.deletingPathExtension().lastPathComponent == named {
                    return fileURL
                }
            }
        }
        
        // If still not found, throw an error
        let errorMessage = "MRC file named '\(named)' could not be found in framework or main app bundle."
        print("File Not Found: \(errorMessage)")
        throw MRCParserError.fileNotFound(errorMessage)
    }
}
