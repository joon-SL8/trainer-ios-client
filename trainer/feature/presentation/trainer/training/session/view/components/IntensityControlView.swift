import SwiftUI

struct IntensityControlView: View {
    @ObservedObject var viewModel: SessionViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Decrease Intensity Button
            Button(action: {
                adjustIntensity(by: -0.05)
            }) {
                Image(systemName: "minus")
                    .font(.title3) // Slightly smaller icon for smaller button
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44) // ~60% of 72
                    .background(Color.blue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(viewModel.intensityFactor <= 0.5)
            
            // Intensity Display
            Text("\(Int(round(viewModel.intensityFactor * 100)))%")
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(width: 45) // Reduced width
            
            // Increase Intensity Button
            Button(action: {
                adjustIntensity(by: 0.05)
            }) {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(viewModel.intensityFactor >= 1.5)
        }
    }
    
    private func adjustIntensity(by delta: Double) {
        let newValue = viewModel.intensityFactor + delta
        viewModel.intensityFactor = max(0.5, min(1.5, newValue))
    }
}

#Preview {
    IntensityControlView(viewModel: SessionViewModel(sensors: [], workout: nil, mrcFilePath: nil, bluetoothManager: BluetoothManager()))
        .padding()
        .background(Color(.systemBackground))
}
