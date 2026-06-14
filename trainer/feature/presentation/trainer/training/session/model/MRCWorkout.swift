import Foundation
import libfitness

public struct MRCBlock: Identifiable, Hashable {
    public let id: UUID
    public let startTime: Double // in minutes
    public let endTime: Double // in minutes
    public let targetPower: Double // percentile

    public init(id: UUID = UUID(), startTime: Double, endTime: Double, targetPower: Double) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.targetPower = targetPower
    }
}

public struct MRCWorkout: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let blocks: [MRCBlock]

    public init(id: UUID = UUID(), name: String, blocks: [MRCBlock]) {
        self.id = id
        self.name = name
        self.blocks = blocks
    }
    
    // Initializer to convert from MrcCourse
    public init(from mrcCourse: MrcCourse) {
        self.id = UUID()
        self.name = mrcCourse.filename
        
        let courseData = mrcCourse.course
        var calculatedBlocks: [MRCBlock] = []
        
        for (index, pair) in courseData.enumerated() {
            let targetPower = pair.first?.floatValue ?? 0.0
            let startTime = pair.second?.floatValue ?? 0.0
            
            let endTime: Float
            if index < courseData.count - 1 {
                endTime = courseData[index + 1].second?.floatValue ?? startTime
            } else {
                // For the last block, we use totalCourseTime
                endTime = Float(mrcCourse.totalCourseTime())
            }
            
            calculatedBlocks.append(MRCBlock(
                startTime: Double(startTime),
                endTime: Double(endTime),
                targetPower: Double(targetPower)
            ))
        }
        
        self.blocks = calculatedBlocks.sorted { $0.startTime < $1.startTime }
    }
}
