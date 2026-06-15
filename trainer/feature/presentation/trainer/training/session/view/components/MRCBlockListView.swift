import SwiftUI

struct MRCBlockListView: View {
    let blocks: [MRCBlock]
    let elapsedTime: TimeInterval
    let intensityFactor: Double
    var isStatic: Bool = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(blocks) { block in
                        let averagePower = (block.targetStartPower + block.targetEndPower) / 2.0
                        let scaledTargetPower = averagePower * intensityFactor
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(formatDuration(block.startTime)) - \(formatDuration(block.endTime)) (\(formatDuration(block.endTime - block.startTime)))")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(scaledTargetPower))% FTP")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            if !isStatic && isCurrent(block) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            PowerZoneDefinition.zone(forPowerPercentage: Int(scaledTargetPower)).swiftColor
                                .opacity((!isStatic && isCurrent(block)) ? 0.35 : ((!isStatic && isCompleted(block)) ? 0.05 : 0.15))
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke((!isStatic && isCurrent(block)) ? PowerZoneDefinition.zone(forPowerPercentage: Int(scaledTargetPower)).swiftColor.opacity(0.8) : Color.clear, lineWidth: 2)
                        )
                        .id(block.id)
                    }
                }
            }
            .onChange(of: elapsedTime) { newTime in
                if !isStatic {
                    scrollToCurrent(proxy: proxy)
                }
            }
            .onAppear {
                if !isStatic {
                    scrollToCurrent(proxy: proxy)
                }
            }
        }
    }
    
    private func scrollToCurrent(proxy: ScrollViewProxy) {
        if let currentBlock = blocks.first(where: { isCurrent($0) }) {
            withAnimation {
                proxy.scrollTo(currentBlock.id, anchor: .center)
            }
        }
    }
    
    private func formatDuration(_ minutes: Double) -> String {
        let mins = Int(minutes)
        let secs = Int((minutes.truncatingRemainder(dividingBy: 1)) * 60)
        return "\(mins):\(String(format: "%02d", secs))"
    }
    
    private func isCurrent(_ block: MRCBlock) -> Bool {
        let currentMinutes = elapsedTime / 60.0
        return currentMinutes >= block.startTime && currentMinutes < block.endTime
    }

    private func isCompleted(_ block: MRCBlock) -> Bool {
        return (elapsedTime / 60.0) >= block.endTime
    }
}
