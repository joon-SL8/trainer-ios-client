import SwiftUI
import libfitness

struct SessionView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @StateObject private var viewModel: SessionViewModel
    @State private var showFileError = false
    @State private var hasShownSummary: Bool = false
    let workoutFile: String?
    
    init(sensors: [MockSensor] = [], course: MrcCourse? = nil, workoutFile: String? = nil, workout: MRCWorkout? = nil, bluetoothManager: BluetoothManager) {
        _viewModel = StateObject(wrappedValue: SessionViewModel(sensors: sensors, workout: workout, mrcFilePath: workoutFile, bluetoothManager: bluetoothManager))
        self.workoutFile = workoutFile
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(0, geometry.size.width - 48) // 24px padding on each side
            let totalHeight = geometry.size.height
            
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Workout Title
                    Text(viewModel.workout?.name ?? "Workout Session")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    
                    // 1. Top Center Header (Requirement 4.1.2) - 20% height
                    SessionMetricHeader(viewModel: viewModel)
                        .frame(width: availableWidth, height: max(0, totalHeight * 0.2))
                        .padding(.horizontal, 24)
                    
                    // 2. Main Area (Requirement 4.1.3 & 4.1.5)
                    HStack(alignment: .top, spacing: 24) {
                        let mainContentWidth = max(0, availableWidth - 24) // subtract internal spacing
                        
                        // Left: MRC Block List (Requirement 4.1.3)
                        MRCBlockListView(
                            blocks: viewModel.workout?.blocks ?? [],
                            elapsedTime: viewModel.elapsedTime,
                            ftp: viewModel.ftp
                        )
                        .frame(width: max(0, mainContentWidth * 0.35))
                        
                        // Right: Controls
                        VStack(alignment: .trailing, spacing: 20) {
                            // Animated State Label
                            Text({
                                switch viewModel.state {
                                case .idle: return "Prep"
                                case .active: return "Ride On"
                                case .paused: return "On a break"
                                case .completed: return "Extra Mile"
                                }
                            }())
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.5), value: viewModel.state)
                            
                            Spacer()
                            
                            // Exit Button
                            Button(action: {
                                viewModel.exitSession()
                                navigationRouter.path.removeLast()
                            }) {
                                Text("Exit")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 32)
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                            
                            // Intensity Controls
                            IntensityControlView(viewModel: viewModel)
                        }
                        .frame(width: max(0, mainContentWidth * 0.65), alignment: .trailing)
                    }
                    .frame(width: availableWidth, height: max(0, totalHeight * 0.5))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    
                    Spacer(minLength: 0)
                    
                    // 3. Bottom Area: Histogram (Requirement 4.1.4)
                    WorkoutHistogramView(
                        blocks: viewModel.workout?.blocks ?? [],
                        elapsedTime: viewModel.elapsedTime,
                        intensityFactor: viewModel.intensityFactor
                    )
                    .frame(width: availableWidth, height: max(0, totalHeight * 0.15))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .frame(width: max(0, geometry.size.width))
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showSummaryModal && !hasShownSummary },
            set: { show in viewModel.showSummaryModal = show }
        ), onDismiss: {
            if !viewModel.showSummaryModal {
                viewModel.resumeTimerObservation()
            }
        }) {
            let metrics = viewModel.calculateSessionMetrics()
            SessionSummaryModalView(
                showModal: $viewModel.showSummaryModal,
                averagePower: metrics.avgPower,
                normalizedPower: metrics.np,
                intensityFactor: metrics.ifFactor,
                tss: metrics.tss,
                powerValues: metrics.powerValues,
                heartRateValues: metrics.heartRateValues,
                cadenceValues: metrics.cadenceValues,
                speedValues: metrics.speedValues,
                onContinue: {
                    hasShownSummary = true
                    viewModel.continueSession()
                    viewModel.resumeTimerObservation()
                },
                onExit: {
                    viewModel.exitSession()
                    navigationRouter.path.removeLast()
                },
                onUpload: {
                    viewModel.onUploadSession()
                }
            )
            .onAppear {
                viewModel.pauseTimerObservation()
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .overlay(
            Group {
                if viewModel.isUploading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2)
                        Text("Uploading to Strava...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                }
            }
        )
        .alert("Upload Error", isPresented: Binding(
            get: { viewModel.uploadErrorMessage != nil },
            set: { _ in viewModel.uploadErrorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.uploadErrorMessage ?? "An unknown error occurred.")
        }
        .onAppear {
            print("SessionView: Became visible.")
            UIApplication.shared.isIdleTimerDisabled = true
            loadWorkout()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .alert("File Not Found", isPresented: $showFileError) {
            Button("OK") {
                navigationRouter.path.removeLast()
            }
        } message: {
            Text("The requested workout file '\(workoutFile ?? "")' could not be found.")
        }
    }
    
    private func loadWorkout() {
        if viewModel.workout != nil {
            // Already loaded via pre-parsed workout
            return
        }

        if let filename = workoutFile {
            if let mrcURL = try? MRCParser.findMRCFile(named: filename) {
                print("opeing mrc file: \(mrcURL)")
                viewModel.workout = try? MRCParser.parse(fileUrl: mrcURL)
                viewModel.requestControl()
            } else {
                showFileError = true
            }
        } else {
            loadRandomWorkout()
            viewModel.requestControl()
        }
    }
    
    private func loadRandomWorkout() {
        if let mrcURL = try? MRCParser.getRandomMRCFile() {
            print("opeing mrc file: \(mrcURL)")
            viewModel.workout = try? MRCParser.parse(fileUrl: mrcURL)
        }
    }
}

#Preview("Connected") {
    SessionView(sensors: [
        MockSensor(name: "H6 Heart Rate", type: .HeartBeat, status: .Connected),
        MockSensor(name: "Kickr Bike", type: .Power, status: .Connected)
    ], bluetoothManager: BluetoothManager())
    .environmentObject(BluetoothManager())
}

#Preview("Disconnected") {
    SessionView(sensors: [
        MockSensor(name: "H6 Heart Rate", type: .HeartBeat, status: .Disconnected),
        MockSensor(name: "Kickr Bike", type: .Power, status: .Disconnected)
    ], bluetoothManager: BluetoothManager())
    .environmentObject(BluetoothManager())
}
