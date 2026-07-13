import SwiftUI
import libfitness

struct LibraryDetailView: View {
    let file: AssetProperty?
    let directoryPath: String?
    let workout: MRCWorkout?
    
    init(file: AssetProperty, directoryPath: String) {
        self.file = file
        self.directoryPath = directoryPath
        self.workout = nil
    }
    
    init(workout: MRCWorkout, filename: String) {
        self.file = nil
        self.directoryPath = nil
        self.workout = workout
    }
    
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var workoutSelectionViewModel: WorkoutSelectionViewModel
    
    @StateObject private var viewModel = LibraryDetailViewModel()
    
    @State private var showSensorSelection = false
    @State private var connectedSensors: [MockSensor] = []
    @State private var showBluetoothExplanation = false
    @State private var showParsingErrorAlert = false

    private var isBluetoothUnavailable: Bool {
        bluetoothManager.permissionDenied || bluetoothManager.state == .poweredOff || bluetoothManager.isUnsupported
    }

    var body: some View {
        contentView
            .overlay {
                if libraryViewModel.isParsing {
                    ParsingProgressModal(progress: libraryViewModel.parsingProgress) {
                        libraryViewModel.cancelParsing()
                    }
                }
            }
            .navigationTitle(workout?.name ?? (file?.data as? String ?? "Detail"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $showSensorSelection, onDismiss: {
                if !connectedSensors.isEmpty {
                    if let workout = workoutSelectionViewModel.workout {
                        navigationRouter.path.append(WorkoutSessionRoute(sensors: connectedSensors, workout: workout))
                        workoutSelectionViewModel.workout = nil
                    }
                }
            }) {
                SensorSelectionView(bluetoothManager: bluetoothManager, workout: workoutSelectionViewModel.workout, onComplete: { sensors, workout in
                    self.connectedSensors = sensors
                    self.workoutSelectionViewModel.workout = workout
                })
            }
            .sheet(isPresented: $showBluetoothExplanation) {
                BluetoothPermissionExplanationView(onDismiss: {
                    showBluetoothExplanation = false
                })
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        navigationRouter.navigateBack()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let filename = workout?.name ?? (file?.data as? String) {
                        Button(action: {
                            viewModel.toggleBookmark(filename: filename)
                        }) {
                            Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(viewModel.isBookmarked ? .blue : .primary)
                        }
                    }
                }
            }
            .onAppear {
                if let workout = workout {
                    print("LibraryDetailView: Loaded with workout: \(workout.name), blocks: \(workout.blocks)")
                    viewModel.loadWorkout(workout, filename: workout.name)
                } else if let file = file, let filename = file.data as? String {
                    print("LibraryDetailView: Parsing file: \(filename)")
                    viewModel.parseFile(named: filename)
                    viewModel.checkBookmarkStatus(filename: filename)
                }
            }
            .onChange(of: libraryViewModel.parsedWorkout) { newValue in
                if let workout = newValue {
                    navigationRouter.path.append(WorkoutSessionRoute(sensors: connectedSensors, workout: workout))
                    libraryViewModel.parsedWorkout = nil
                }
            }
            .onChange(of: libraryViewModel.parsingError) { newValue in
                if newValue != nil {
                    showParsingErrorAlert = true
                }
            }
            .alert("Parsing Failed", isPresented: $showParsingErrorAlert) {
                Button("OK") {
                    libraryViewModel.parsingError = nil
                }
            } message: {
                Text(libraryViewModel.parsingError ?? "Unknown error")
            }
    }

    @ViewBuilder
    private var contentView: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Parsing file...")
            } else if let errorMessage = viewModel.errorMessage {
                errorSection(errorMessage)
            } else if let course = viewModel.course {
                courseContent(course)
            } else {
                Text("Failed to parse file content.")
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func errorSection(_ errorMessage: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Proceed anyway") {
                // If we proceed, we should treat it as an empty workout, 
                // or use a fallback if one exists in the view model.
                // For now, let's create an empty workout as a placeholder.
                let emptyWorkout = MRCWorkout(name: "Empty Workout", blocks: [])
                viewModel.workout = emptyWorkout
                viewModel.errorMessage = nil
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .foregroundColor(.secondary)
    }

    @ViewBuilder
    private func courseContent(_ course: MrcCourse) -> some View {
        let workout = self.workout ?? viewModel.workout ?? {
            let w = MRCWorkout(from: course)
            w.process()
            return w
        }()
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection(course)
                Divider()
                detailsSection(course)
                descriptionSection(course)
                intervalsSection(workout)
                profileSection(workout)
            }
            .padding()
        }
    }

    private func headerSection(_ course: MrcCourse) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(course.filename)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Version: \(course.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private func detailsSection(_ course: MrcCourse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow(label: "Total Time", value: TimeUtils.formatDuration(Double(course.totalCourseTime())))
            detailRow(label: "Training Stress Score", value: String(format: "%.1f", viewModel.tss))
            HStack {
                detailRow(label: "NP", value: String(format: "%.1fW", viewModel.np))
                Spacer()
                detailRow(label: "FTP", value: String(format: "%.1fW", viewModel.ftp))
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func descriptionSection(_ course: MrcCourse) -> some View {
        if !course.description_.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Description")
                        .font(.headline)
                    Spacer()
                    playButton(course)
                }
                Text(course.description_)
                    .font(.body)
            }
        } else {
            HStack {
                Text("Details")
                    .font(.headline)
                Spacer()
                playButton(course)
            }
        }
    }

    @ViewBuilder
    private func intervalsSection(_ workout: MRCWorkout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intervals")
                .font(.headline)
            MRCBlockListView(blocks: workout.blocks, elapsedTime: 0, ftp: viewModel.ftp, isStatic: true)
                .frame(height: 200)
        }
    }

    @ViewBuilder
    private func profileSection(_ workout: MRCWorkout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profile")
                .font(.headline)
            // Use the same intensityFactor as MRCBlockListView for consistent coloring if applicable.
            // Note: WorkoutHistogramView doesn't seem to support per-block zone colors natively,
            // keeping it as is but note this limitation if the user requires per-zone colors in histogram.
            WorkoutHistogramView(blocks: workout.blocks, elapsedTime: 0, intensityFactor: 1.0, isStatic: true)
                .frame(height: 150)
        }
    }

    private func playButton(_ course: MrcCourse) -> some View {
        Button(action: {
            if isBluetoothUnavailable {
                showBluetoothExplanation = true
            } else {
                bluetoothManager.requestPermission()
                let workout = MRCWorkout(from: course)
                workout.process()
                workoutSelectionViewModel.workout = workout
                workoutSelectionViewModel.showSensorSelection = true
                navigationRouter.navigateBack()
            }
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start")
            }
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.blue)
            .cornerRadius(20)
        }
        .accessibilityIdentifier("startSessionButton")
    }
}
