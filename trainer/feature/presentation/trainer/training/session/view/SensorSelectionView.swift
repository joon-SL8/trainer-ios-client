import SwiftUI

struct SensorSelectionView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @StateObject var viewModel: SensorSelectionViewModel
    @Environment(\.dismiss) var dismiss
    var onComplete: (([MockSensor], MRCWorkout?) -> Void)?
    
    init(bluetoothManager: BluetoothManager, workout: MRCWorkout?, onComplete: (([MockSensor], MRCWorkout?) -> Void)? = nil) {
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: SensorSelectionViewModel(bluetoothManager: bluetoothManager, workout: workout))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isScanning && viewModel.sensors.isEmpty {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Searching for sensors...")
                            .padding()
                    }
                    .frame(maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            viewModel.startScanning()
                        }) {
                            Text("Scan Again")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.sensors) { (sensor: MockSensor) in
                                Button(action: {
                                    viewModel.connect(to: sensor)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(sensor.name)
                                                .font(.headline)
                                            if let bluetoothSensor = sensor.bluetoothSensor, !bluetoothSensor.advertisedServiceUUIDs.isEmpty {
                                                Text("Services: \(bluetoothSensor.advertisedServiceUUIDs.joined(separator: ", "))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Text(sensorText(sensor.type))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        
                                        if sensor.status == .Connecting {
                                            ProgressView()
                                        } else {
                                            Text(statusText(sensor.status))
                                                .font(.caption)
                                                .padding(6)
                                                .background(statusColor(sensor.status).opacity(0.1))
                                                .foregroundColor(statusColor(sensor.status))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .disabled(sensor.status == .Connecting)
                            }
                        }
                        .padding()
                    }
                }
                
                VStack(spacing: 10) {
                    if viewModel.hasConnectedSensors {
                        Button(action: {
                            bluetoothManager.stopScanning()
                            onComplete?(viewModel.selectedSensors, viewModel.workout)
                            dismiss()
                        }) {
                            Text("Start Training")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .accessibilityIdentifier("startTrainingButton")
                    }
                    
                    if viewModel.sensors.count > 0 && !viewModel.isScanning {
                        Button(action: {
                            viewModel.startScanning()
                        }) {
                            Text("Scan Again")
                                .font(.subheadline)
                        }
                        .padding(.bottom, 5)
                    }
                }
            }
            .navigationTitle("Select Sensor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if viewModel.isScanning {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Button(action: {
                            viewModel.stopScanning()
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .alert("Bluetooth Required", isPresented: $viewModel.showBluetoothSettingsAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Bluetooth is required to scan for sensors. Please enable it in Settings.")
            }
            .onAppear {
                print("SensorSelectionView: Became visible.")
                viewModel.startScanning()
            }
        }
    }
    
    private func statusColor(_ status: Status) -> Color {
        switch status {
        case .Connected: return .green
        case .Connecting: return .blue
        default: return .secondary
        }
    }
    
    private func statusText(_ status: Status) -> String {
        switch status {
        case .Connected: return "Connected"
        case .Connecting: return "Connecting..."
        case .Discovered: return "Discovered"
        case .Disconnected: return "Disconnected"
        default: return ""
        }
    }
    
    private func sensorText(_ type: SensorType) -> String {
        switch type {
        case .HeartBeat: return "Heart Rate"
        case .Power: return "Power"
        default: return "Sensor"
        }
    }
}

#Preview {
    SensorSelectionView(bluetoothManager: BluetoothManager(), workout: nil)
}
