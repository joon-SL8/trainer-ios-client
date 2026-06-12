import XCTest
@testable import trainer

final class MRCParserTests: XCTestCase {
    
    func testParseValidMRC() throws {
        let content = """
[COURSE HEADER]
MINUTES PERCENT
[END COURSE HEADER]
[COURSE DATA]
0.00\t50
4.00\t50
4.00\t100
10.00\t100
[END COURSE DATA]
"""
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.mrc")
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let workout = MRCParser.parse(fileUrl: tempURL)
        XCTAssertNotNil(workout)
        XCTAssertEqual(workout?.blocks.count, 2)
        XCTAssertEqual(workout?.blocks[0].startTime, 0.0)
        XCTAssertEqual(workout?.blocks[0].endTime, 4.0)
        XCTAssertEqual(workout?.blocks[0].targetPower, 50.0)
        
        XCTAssertEqual(workout?.blocks[1].startTime, 4.0)
        XCTAssertEqual(workout?.blocks[1].endTime, 10.0)
        XCTAssertEqual(workout?.blocks[1].targetPower, 100.0)
    }
    
    func testParseMalformedPairs() throws {
        let content = """
[COURSE DATA]
0.00\t50
4.00\t50
10.00\t100
[END COURSE DATA]
"""
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("malformed.mrc")
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let workout = MRCParser.parse(fileUrl: tempURL)
        XCTAssertNotNil(workout)
        XCTAssertEqual(workout?.blocks.count, 1) // Only first pair is valid
    }
    
    func testParseAsync() async throws {
        let content = """
[COURSE DATA]
0.0\t50
5.0\t50
5.0\t100
10.0\t100
[END COURSE DATA]
"""
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("testAsync.mrc")
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        var progressValues: [Double] = []
        let workout = try await MRCParser.parseAsync(fileUrl: tempURL) { progress in
            progressValues.append(progress)
        }
        
        XCTAssertNotNil(workout)
        XCTAssertEqual(workout?.blocks.count, 2)
        XCTAssert(progressValues.contains(where: { $0 >= 0.0 }))
        XCTAssertEqual(progressValues.last, 1.0)
    }
    
    func testParseAsyncCancellation() async throws {
        let content = (0..<100).map { i in "\(Double(i))\t50\n\(Double(i)+1.0)\t50" }.joined(separator: "\n")
        let fullContent = "[COURSE DATA]\n\(content)\n[END COURSE DATA]"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("testCancel.mrc")
        try fullContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let task = Task {
            try await MRCParser.parseAsync(fileUrl: tempURL) { _ in }
        }
        
        // Cancel immediately
        task.cancel()
        
        do {
            _ = try await task.value
            XCTFail("Should have thrown CancellationError")
        } catch is CancellationError {
            // Success
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testGetRandomMRCFile() throws {
        // Now it should try to find a bundled file, and can throw
        let url = try MRCParser.getRandomMRCFile()
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.pathExtension.lowercased(), "mrc")
    }

    func testFindBundledMRCFile() throws {
        // Assuming "training-3min.mrc" is now correctly bundled with the main app target
        let mrcFileUrl = try MRCParser.findMRCFile(named: "training-3min")
        XCTAssertNotNil(mrcFileUrl)
        XCTAssertEqual(mrcFileUrl?.lastPathComponent, "training-3min.mrc")
        
        // Try to parse it to ensure it's a valid file
        let workout = try MRCParser.parse(fileUrl: mrcFileUrl!)
        XCTAssertNotNil(workout)
        XCTAssertFalse(workout!.blocks.isEmpty)
    }

    func testFindNonExistentMRCFileThrowsError() {
        XCTAssertThrowsError(try MRCParser.findMRCFile(named: "nonExistentFile")) { error in
            XCTAssertTrue(error is MRCParserError)
            if let mrcError = error as? MRCParserError {
                XCTAssertEqual(mrcError.localizedDescription, MRCParserError.fileNotFound("MRC file named 'nonExistentFile' could not be found in framework or main app bundle.").localizedDescription)
            }
        }
    }
}
