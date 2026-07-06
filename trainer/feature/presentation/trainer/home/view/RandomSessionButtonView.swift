import SwiftUI

struct RandomSessionButtonView: View {
    @ObservedObject var viewModel: RandomSessionViewModel
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @ObservedObject var workoutSelectionViewModel: WorkoutSelectionViewModel
    @EnvironmentObject var navigationRouter: NavigationRouter
    @State private var tss: Double = 0.0
    
    var isBluetoothUnavailable: Bool {
        if bluetoothManager.isMocking { return false }
        return bluetoothManager.permissionDenied || bluetoothManager.state == .poweredOff || bluetoothManager.isUnsupported
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            mainButton
            
            Button(action: {
                print("DEBUG: Reset button tapped")
                viewModel.fetchRandomWorkout()
            }) {
                Image("ic_reset")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .contentShape(Rectangle())
            }
            .padding(4)
            .accessibilityIdentifier("resetWorkoutButton")
        }
    }

    private var mainButton: some View {
        Button(action: {
            print("DEBUG: Main workout button tapped")
            if let workout = viewModel.workout {
                print("DEBUG: Navigating to LibraryDetailRoute for workout: \(workout.name)")
                navigationRouter.path.append(LibraryDetailRoute(workout: workout))
            } else {
                print("DEBUG: No workout available")
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Workout")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let workout = viewModel.workout {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(workout.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("Est. TSS: \(String(format: "%.1f", tss))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Total time: \(TimeUtils.formatDuration(workout.blocks.last?.endTime ?? 0))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        WorkoutHistogramView(blocks: workout.blocks, elapsedTime: 0, intensityFactor: 1.0, isStatic: true)
                            .frame(height: 50)
                    }
                    .onAppear {
                        Task {
                            self.tss = await viewModel.calculateEstimatedTSS(workout: workout)
                        }
                    }
                    .onChange(of: viewModel.workout) { newWorkout in
                        if let newWorkout = newWorkout {
                            Task {
                                self.tss = await viewModel.calculateEstimatedTSS(workout: newWorkout)
                            }
                        }
                    }
                } else if viewModel.isLoading {
                    // ... (rest remains same)
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding()
                }
            }
            // ... (rest of modifier remains same)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
        }
        .disabled(viewModel.workout == nil)
        .accessibilityIdentifier("randomSessionButton")
    }
    // ... (rest of helper remains same)
    

}
