import Foundation
import libfitness

public struct WorkoutSessionRoute: Hashable {
    public let sensors: [MockSensor]
    public let course: MrcCourse?
    public let workoutFile: String?
    public let workout: MRCWorkout?

    public init(sensors: [MockSensor], course: MrcCourse? = nil, workoutFile: String? = nil, workout: MRCWorkout? = nil) {
        self.sensors = sensors
        self.course = course
        self.workoutFile = workoutFile
        self.workout = workout
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sensors)
        hasher.combine(workoutFile)
        hasher.combine(workout?.id)
        // MrcCourse is a class from libfitness, which inherits from NSObject (via libfitness).
        // It provides pointer equality and hash by default.
        if let course = course {
            hasher.combine(ObjectIdentifier(course))
        } else {
            hasher.combine(0)
        }
    }

    public static func == (lhs: WorkoutSessionRoute, rhs: WorkoutSessionRoute) -> Bool {
        lhs.sensors == rhs.sensors && 
        lhs.course === rhs.course && 
        lhs.workoutFile == rhs.workoutFile &&
        lhs.workout?.id == rhs.workout?.id
    }
}
