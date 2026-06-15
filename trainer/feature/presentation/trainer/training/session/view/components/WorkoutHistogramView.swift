import SwiftUI

struct WorkoutHistogramView: View {
    let blocks: [MRCBlock]
    let elapsedTime: TimeInterval
    let intensityFactor: Double
    var isStatic: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            if blocks.isEmpty {
                Color.clear
            } else {
                let totalTime = blocks.last?.endTime ?? 1
                let maxPower = max(100, blocks.map { (($0.targetStartPower + $0.targetEndPower) / 2.0) * intensityFactor }.max() ?? 100)
                
                ZStack(alignment: .bottomLeading) {
                    // Base Layer: Entire Profile
                    workoutProfile(blocks: blocks, totalTime: totalTime, maxPower: maxPower, opacity: isStatic ? 0.8 : 0.2, geometry: geometry)
                    
                    if !isStatic {
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
        let width = geometry.size.width
        let height = geometry.size.height

        Path { path in
            path.move(to: CGPoint(x: 0, y: height)) // Start at bottom left
            
            for block in blocks {
                let startX = CGFloat(block.startTime / totalTimeSafe) * width
                let endX = CGFloat(block.endTime / totalTimeSafe) * width
                let startY = height - CGFloat(((block.targetStartPower + block.targetEndPower) / 2.0) * intensityFactor / maxPowerSafe) * height
                let endY = height - CGFloat(((block.targetStartPower + block.targetEndPower) / 2.0) * intensityFactor / maxPowerSafe) * height
                
                path.addLine(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            path.addLine(to: CGPoint(x: width, y: height)) // End at bottom right
            path.closeSubpath()
        }
        .fill(Color.blue.opacity(opacity))
    }
}
