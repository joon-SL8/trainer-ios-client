import Foundation
import libfitness

public class MRCCourseMapper {
    public static func map(workout: MRCWorkout) -> MrcCourse {
        let course = workout.blocks.map { block in
            // Libfitness expected float pairs for power and time
            let averagePower = (block.targetStartPower + block.targetEndPower) / 2.0
            return KotlinPair(
                first: KotlinFloat(float: Float(averagePower)),
                second: KotlinFloat(float: Float(block.startTime)) // Assuming start time as reference
            )
        }
        
        // Construct MrcCourse
        // version: "1.0", units: "watts", description: workout.name, filename: workout.name, shortFileName: workout.name, course: course, text: []
        return MrcCourse(
            version: "1.0",
            units: "watts",
            description: workout.name,
            filename: workout.name,
            shortFileName: workout.name,
            course: course,
            text: []
        )
    }
}
