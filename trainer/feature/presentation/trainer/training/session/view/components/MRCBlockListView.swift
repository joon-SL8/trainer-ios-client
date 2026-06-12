import SwiftUI

struct MRCBlockListView: View {
    let blocks: [MRCBlock]
    let elapsedTime: TimeInterval
    let intensityFactor: Double
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(blocks) { block in
                        let scaledTargetPower = block.targetPower * intensityFactor
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(formatTime(block.startTime)) - \(formatTime(block.endTime))")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(scaledTargetPower))% FTP")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            if isCurrent(block) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            PowerZoneDefinition.zone(forPowerPercentage: Int(scaledTargetPower)).swiftColor
                                .opacity(isCurrent(block) ? 0.35 : (isCompleted(block) ? 0.05 : 0.15))
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isCurrent(block) ? PowerZoneDefinition.zone(forPowerPercentage: Int(scaledTargetPower)).swiftColor.opacity(0.8) : Color.clear, lineWidth: 2)
                        )
                        .id(block.id)
                    }
                }
            }
            .onChange(of: elapsedTime) { newTime in
                scrollToCurrent(proxy: proxy)
            }
            .onAppear {
                scrollToCurrent(proxy: proxy)
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
    
    private func formatTime(_ minutes: Double) -> String {
        let mins = Int(minutes)
        let secs = Int((minutes.truncatingRemainder(dividingBy: 1)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func isCurrent(_ block: MRCBlock) -> Bool {
        let currentMinutes = elapsedTime / 60.0
        return currentMinutes >= block.startTime && currentMinutes < block.endTime
    }

    private func isCompleted(_ block: MRCBlock) -> Bool {
        return (elapsedTime / 60.0) >= block.endTime
    }
}
