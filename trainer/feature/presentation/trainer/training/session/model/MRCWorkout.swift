import Foundation
import libfitness

public struct MRCBlock: Identifiable, Hashable {
    public let id: UUID
    public let startTime: Double // in minutes
    public let endTime: Double // in minutes
    public let targetStartPower: Double // percentile
    public let targetEndPower: Double // percentile

    public init(id: UUID = UUID(), startTime: Double, endTime: Double, targetStartPower: Double, targetEndPower: Double) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.targetStartPower = targetStartPower
        self.targetEndPower = targetEndPower
    }
}

public class MRCWorkout: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public private(set) var blocks: [MRCBlock]
    private var mrcCourse: MrcCourse?
    private var isProcessed: Bool = false

    public init(id: UUID = UUID(), name: String, blocks: [MRCBlock]) {
        self.id = id
        self.name = name
        self.blocks = blocks
        self.mrcCourse = nil
        self.isProcessed = true
    }
    
    // Initializer to convert from MrcCourse
    public init(from mrcCourse: MrcCourse) {
        self.id = UUID()
        self.name = mrcCourse.filename
        self.blocks = []
        self.mrcCourse = mrcCourse
        self.isProcessed = false
    }
    
    public func process() {
        guard !isProcessed, let mrcCourse = self.mrcCourse else { return }
        
        var courseData = mrcCourse.course
        if courseData.count % 2 != 0 {
            if let lastItem = courseData.last {
                courseData.append(lastItem)
            }
        }

        var calculatedBlocks: [MRCBlock] = []

        // Consume in pairs
        for i in stride(from: 0, to: courseData.count, by: 2) {
            guard let pair1 = courseData[i] as? KotlinPair<KotlinFloat, KotlinFloat>,
                  let pair2 = courseData[i+1] as? KotlinPair<KotlinFloat, KotlinFloat> else { continue }
            
            let startTime = Double(pair1.first?.floatValue ?? 0.0)
            let startPower = Double(pair1.second?.floatValue ?? 0.0)
            
            let endTime = Double(pair2.first?.floatValue ?? 0.0)
            let endPower = Double(pair2.second?.floatValue ?? 0.0)
            
            calculatedBlocks.append(MRCBlock(
                startTime: startTime,
                endTime: endTime,
                targetStartPower: startPower,
                targetEndPower: endPower
            ))
        }
        
        self.blocks = calculatedBlocks.sorted { $0.startTime < $1.startTime }
        self.isProcessed = true
    }
    
    public static func == (lhs: MRCWorkout, rhs: MRCWorkout) -> Bool {
        lhs.id == rhs.id
    }
}
