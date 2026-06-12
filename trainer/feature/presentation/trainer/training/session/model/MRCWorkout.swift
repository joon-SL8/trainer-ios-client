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
        self.blocks = mrcCourse.course.compactMap { kotlinPairAny in
            guard let kotlinPair = kotlinPairAny as? KotlinPair<KotlinFloat, KotlinFloat> else { return nil }
            
            let targetPower = kotlinPair.first?.floatValue ?? 0.0
            let startTime = kotlinPair.second?.floatValue ?? 0.0
            
            // PROBLEM: MrcCourse.course only provides (targetPower, startTime). It does not provide endTime.
            // For now, setting endTime to startTime as a placeholder to prevent KVC crash.
            // This needs further investigation and proper mapping for endTime.
            return MRCBlock(
                startTime: Double(startTime),
                endTime: Double(startTime + 1.0), // Placeholder: assuming each block has a duration of 1 minute for now to avoid zero duration.
                targetPower: Double(targetPower)
            )
        }
    }
}
