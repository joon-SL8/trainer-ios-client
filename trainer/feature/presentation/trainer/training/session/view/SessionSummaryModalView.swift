import SwiftUI
import libfitness

struct SessionSummaryModalView: View {
    @Binding var showModal: Bool
    let averagePower: Double
    let normalizedPower: Double
    let intensityFactor: Double
    let tss: Double
    let powerValues: [Double]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Session Summary")
                .font(.headline)
            
            // 2x2 Grid for metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                MetricView(title: "Avg Power", value: "\(Int(averagePower))W")
                MetricView(title: "NP", value: "\(Int(normalizedPower))W")
                MetricView(title: "IF", value: String(format: "%.2f", intensityFactor))
                MetricView(title: "TSS", value: "\(Int(tss))")
            }
            .padding()
            
            // Histogram
            // WorkoutHistogramView(powers: powerValues)
            Text("Histogram placeholder")
            
            Button("Close") {
                showModal = false
            }
            .padding()
        }
        .padding()
    }
}

struct MetricView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
