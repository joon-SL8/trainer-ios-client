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
                // Ensure minimum scale is 120, or add 10% padding if max power exceeds 120
                let rawMaxPower = blocks.map { max($0.targetStartPower, $0.targetEndPower) * intensityFactor }.max() ?? 100
                let maxPower = max(120, rawMaxPower * 1.1)

                let ftpY: CGFloat = (rawMaxPower < 100) ? (geometry.size.height * 0.2) : (geometry.size.height - CGFloat(100.0 / maxPower) * geometry.size.height)

                ZStack(alignment: .bottomLeading) {
                    // Base Layer: Entire Profile
                    workoutProfile(blocks: blocks, totalTime: totalTime, maxPower: maxPower, geometry: geometry)

                    // FTP Indicator Line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: ftpY))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: ftpY))
                    }
                    .stroke(Color.yellow, lineWidth: 3)

                    Text("FTP")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.trailing, 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .baselineOffset(geometry.size.height - ftpY + 2)
                        
                    // Progress cursor (Time Vertical Line)
                    if !isStatic {
                        let totalTime = blocks.last?.endTime ?? 1
                        let progressMinutes = elapsedTime / 60.0
                        let totalTimeSafe = max(0.001, totalTime)
                        let widthSafe = max(0, geometry.size.width)
                        let progressX = CGFloat(progressMinutes / totalTimeSafe) * widthSafe
                        
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 2)
                            .offset(x: max(0, min(progressX, widthSafe)))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }
    
    @ViewBuilder
    private func workoutProfile(blocks: [MRCBlock], totalTime: Double, maxPower: Double, geometry: GeometryProxy) -> some View {
        let totalTimeSafe = max(0.001, totalTime)
        let maxPowerSafe = max(1.0, maxPower)
        let width = geometry.size.width
        let height = geometry.size.height
        let cornerRadius: CGFloat = 4
        let currentTimeMinutes = elapsedTime / 60.0

        ZStack(alignment: .bottomLeading) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                let startX = CGFloat(block.startTime / totalTimeSafe) * width
                let endX = CGFloat(block.endTime / totalTimeSafe) * width
                
                let startY = height - CGFloat((block.targetStartPower * intensityFactor) / maxPowerSafe) * height
                let endY = height - CGFloat((block.targetEndPower * intensityFactor) / maxPowerSafe) * height
                
                let startColor = PowerZoneDefinition.color(forPowerPercentage: block.targetStartPower * intensityFactor)
                let endColor = PowerZoneDefinition.color(forPowerPercentage: block.targetEndPower * intensityFactor)
                
                let blockOpacity: Double = isStatic ? 0.8 : ((block.endTime <= currentTimeMinutes) ? 1.0 : 0.8)
                
                Path { path in
                    path.move(to: CGPoint(x: startX, y: height))
                    path.addLine(to: CGPoint(x: endX, y: height))
                    // Top-right corner
                    path.addLine(to: CGPoint(x: endX, y: endY + cornerRadius))
                    path.addArc(center: CGPoint(x: endX - cornerRadius, y: endY + cornerRadius), radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(-90), clockwise: true)
                    // Top-left corner
                    path.addLine(to: CGPoint(x: startX + cornerRadius, y: startY))
                    path.addArc(center: CGPoint(x: startX + cornerRadius, y: startY + cornerRadius), radius: cornerRadius, startAngle: .degrees(-90), endAngle: .degrees(180), clockwise: true)
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(colors: [startColor, endColor], startPoint: .leading, endPoint: .trailing)
                )
                .opacity(blockOpacity)
            }
        }
    }
}
