import SwiftUI
import libfitness

struct SessionMetricHeader: View {
    @ObservedObject var viewModel: SessionViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 8
            let totalAvailableWidth = max(0, geometry.size.width - (spacing * 2))
            let sideWidth = totalAvailableWidth * 0.30
            let centerWidth = totalAvailableWidth * 0.40
            
            HStack(spacing: spacing) {
                // Left Column: Speed, Heart Rate
                VStack(spacing: 8) {
                    MetricBox(
                        title: "Speed",
                        value: viewModel.speed != nil ? String(format: "%.1f", viewModel.speed!) : "--",
                        unit: "km/h",
                        isConnected: viewModel.isPowerConnected,
                        color: .green
                    )
                    
                    MetricBox(
                        title: "Heart Rate",
                        value: viewModel.currentHeartRateContent != nil ? String(format: "%.0f", Double(viewModel.currentHeartRateContent!.content.hrData)) : "--",
                        unit: "BPM",
                        isConnected: viewModel.currentHeartRateContent != nil,
                        color: .red
                    )
                }
                .frame(width: sideWidth)

                // Middle Column: Power, Total Time
                VStack(spacing: 8) {
                    MetricBox(
                        title: "Power",
                        value: viewModel.power != nil ? String(format: "%.0f", viewModel.power!) : "--",
                        unit: "W",
                        isConnected: viewModel.isPowerConnected,
                        color: .blue
                    )
                    
                    MetricBox(
                        title: "Total Time",
                        value: formatTimeInterval(viewModel.elapsedTime),
                        unit: "",
                        isConnected: viewModel.workout != nil,
                        color: .secondary
                    )
                }
                .frame(width: centerWidth)

                // Right Column: Cadence, Interval Time
                VStack(spacing: 8) {
                    MetricBox(
                        title: "Cadence",
                        value: viewModel.cadence != nil ? String(format: "%.0f", viewModel.cadence!) : "--",
                        unit: "RPM",
                        isConnected: viewModel.isCadenceConnected,
                        color: .purple
                    )
                    
                    MetricBox(
                        title: "Interval",
                        value: viewModel.formattedBlockProgress,
                        unit: "",
                        isConnected: viewModel.workout != nil,
                        color: viewModel.currentBlockZoneColor,
                        progress: viewModel.blockProgressPercentage
                    )
                }
                .frame(width: sideWidth)
            }
                }
                }

                private func formatTimeInterval(_ interval: TimeInterval) -> String {
                let minutes = Int(interval) / 60
                let seconds = Int(interval) % 60
                return String(format: "%02d:%02d", minutes, seconds)
                }
}
