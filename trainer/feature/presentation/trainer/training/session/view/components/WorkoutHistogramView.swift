import SwiftUI

struct WorkoutHistogramView: View {
    let blocks: [MRCBlock]
    let elapsedTime: TimeInterval
    let intensityFactor: Double
    
    var body: some View {
        GeometryReader { geometry in
            if blocks.isEmpty {
                Color.clear
            } else {
                let totalTime = blocks.last?.endTime ?? 1
                let maxPower = max(100, blocks.map { $0.targetPower * intensityFactor }.max() ?? 100)
                
                ZStack(alignment: .bottomLeading) {
                    // Base Layer: Entire Profile (Pale/Completed state)
                    workoutProfile(blocks: blocks, totalTime: totalTime, maxPower: maxPower, opacity: 0.2, geometry: geometry)
                    
                    // Progress Layer: Future Profile (Bright state)
                    let progressMinutes = elapsedTime / 60.0
                    let totalTimeSafe = max(0.001, totalTime)
                    let widthSafe = max(0, geometry.size.width)
                    let progressX = CGFloat(progressMinutes / totalTimeSafe) * widthSafe
                    
                    workoutProfile(blocks: blocks, totalTime: totalTime, maxPower: maxPower, opacity: 0.6, geometry: geometry)
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: max(0, min(progressX, widthSafe)))
                                Rectangle()
                                    .fill(Color.black)
                                Spacer(minLength: 0)
                            }
                        )
                    
                    // Progress cursor
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 2)
                        .offset(x: max(0, min(progressX, widthSafe)))
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }
    
    @ViewBuilder
    private func workoutProfile(blocks: [MRCBlock], totalTime: Double, maxPower: Double, opacity: Double, geometry: GeometryProxy) -> some View {
        let totalTimeSafe = max(0.001, totalTime)
        let maxPowerSafe = max(1.0, maxPower)
        let widthSafe = max(0, geometry.size.width)
        let heightSafe = max(0, geometry.size.height)
        
        return HStack(alignment: .bottom, spacing: 0) {
            ForEach(blocks) { block in
                let scaledTargetPower = block.targetPower * intensityFactor
                let blockWidth = CGFloat((block.endTime - block.startTime) / totalTimeSafe) * widthSafe
                let blockHeight = CGFloat(scaledTargetPower / maxPowerSafe) * heightSafe
                let zone = PowerZoneDefinition.zone(forPowerPercentage: Int(scaledTargetPower))
                
                Rectangle()
                    .fill(zone.swiftColor.opacity(opacity))
                    .frame(width: max(0, blockWidth), height: max(0, blockHeight))
            }
        }
    }
}
