import Foundation
import libfitness

public struct WorkoutSessionRoute: Hashable {
    public let sensors: [MockSensor]
    public let course: MrcCourse?
    public let workoutFile: String?
    public let workout: MRCWorkout?
    public let sessionId: String?

    public init(sensors: [MockSensor], course: MrcCourse? = nil, workoutFile: String? = nil, workout: MRCWorkout? = nil, sessionId: String? = nil) {
        self.sensors = sensors
        self.course = course
        self.workoutFile = workoutFile
        self.workout = workout
        self.sessionId = sessionId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sensors)
        hasher.combine(workoutFile)
        hasher.combine(workout?.id)
        hasher.combine(sessionId)
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
        lhs.workout?.id == rhs.workout?.id &&
        lhs.sessionId == rhs.sessionId
    }
}

public struct LibraryDetailRoute: Hashable {
    public let workout: MRCWorkout

    public init(workout: MRCWorkout) {
        self.workout = workout
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(workout.id)
    }

    public static func == (lhs: LibraryDetailRoute, rhs: LibraryDetailRoute) -> Bool {
        lhs.workout.id == rhs.workout.id
    }
}
