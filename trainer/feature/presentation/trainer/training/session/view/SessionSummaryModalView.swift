import SwiftUI
import libfitness

struct SessionSummaryModalView: View {
    @Binding var showModal: Bool
    let averagePower: Double
    let normalizedPower: Double
    let intensityFactor: Double
    let tss: Double
    let powerValues: [Double]
    let heartRateValues: [Double]
    let cadenceValues: [Double]
    let speedValues: [Double]
    let onContinue: () -> Void
    let onExit: () -> Void
    
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
            
            // Histograms
            ScrollView {
                VStack(spacing: 16) {
                    LineGraphView(title: "Power", data: powerValues)
                    LineGraphView(title: "Heart Rate", data: heartRateValues)
                    LineGraphView(title: "Cadence", data: cadenceValues)
                    LineGraphView(title: "Speed", data: speedValues)
                }
                .padding(.horizontal, 24)
            }
            
            VStack(spacing: 8) {
                Button(action: {
                    // TODO: Implement Upload
                }) {
                    Text("Upload")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    onExit()
                }) {
                    Text("Exit")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 2))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 24)
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
