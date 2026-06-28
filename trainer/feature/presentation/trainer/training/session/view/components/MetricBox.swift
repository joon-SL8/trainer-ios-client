import SwiftUI

struct MetricBox: View {
    let title: String
    let value: String
    let unit: String
    let isConnected: Bool
    let color: Color
    var progress: Double? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                .frame(maxHeight: .infinity)
            }
            
            if let progress = progress, title.isEmpty {
                // Progress Bar Section (Top 50%)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(color.opacity(0.15))
                        
                        Rectangle()
                            .fill(color.opacity(0.7))
                            .frame(width: max(0, geo.size.width * CGFloat(progress)))
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Value Section (Bottom 50%)
                HStack(alignment: .center, spacing: 2) {
                    Text(isConnected ? value : "-")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(isConnected ? value : "-")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    if isConnected && !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 0)
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isConnected ? color.opacity(0.8) : Color.gray.opacity(0.3), lineWidth: 2)
        )
        .opacity(isConnected ? 1.0 : 0.6)
    }
}

#Preview {
    HStack {
        MetricBox(title: "Heart Rate", value: "145", unit: "BPM", isConnected: true, color: .red)
        MetricBox(title: "Power", value: "250", unit: "W", isConnected: false, color: .blue)
    }
    .frame(height: 100)
    .padding()
}
