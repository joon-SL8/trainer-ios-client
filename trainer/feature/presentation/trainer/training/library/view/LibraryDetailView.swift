import SwiftUI
import libfitness

struct LibraryDetailView: View {
    let file: AssetProperty
    let directoryPath: String
    
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var workoutSelectionViewModel: WorkoutSelectionViewModel
    @State private var course: MrcCourse? = nil
    @State private var workout: MRCWorkout? = nil
    @State private var isBookmarked: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    @State private var showSensorSelection = false
    @State private var connectedSensors: [MockSensor] = []
    @State private var showBluetoothExplanation = false
    @State private var showParsingErrorAlert = false

    private var isBluetoothUnavailable: Bool {
        bluetoothManager.permissionDenied || bluetoothManager.state == .poweredOff || bluetoothManager.isUnsupported
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Parsing file...")
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .foregroundColor(.secondary)
            } else if let course = course {
                let workout = MRCWorkout(from: course)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection(course)
                        
                        Divider()
                        
                        detailsSection(course)
                        
                        if !course.description_.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Description")
                                        .font(.headline)
                                    Spacer()
                                    playButton(course)
                                    viewRawButton(course)
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Intervals")
                                .font(.headline)
                            MRCBlockListView(blocks: workout.blocks, elapsedTime: 0, intensityFactor: 1.0, isStatic: true)
                                .frame(height: 200)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Profile")
                                .font(.headline)
                            WorkoutHistogramView(blocks: workout.blocks, elapsedTime: 0, intensityFactor: 1.0, isStatic: true)
                                .frame(height: 150)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Failed to parse file content.")
                    .foregroundColor(.secondary)
            }
        }
        .overlay {
            if libraryViewModel.isParsing {
                ParsingProgressModal(progress: libraryViewModel.parsingProgress) {
                    libraryViewModel.cancelParsing()
                }
            }
        }
        .navigationTitle(file.data as? String ?? "Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showSensorSelection, onDismiss: {
            if !connectedSensors.isEmpty {
                // If a workout was chosen in LibraryDetailView and sensors connected,
                // trigger the navigation with the workout through WorkoutSelectionViewModel
                if let workout = workoutSelectionViewModel.workout {
                    navigationRouter.path.append(WorkoutSessionRoute(sensors: connectedSensors, workout: workout))
                    // Clear workout from ViewModel after use
                    workoutSelectionViewModel.workout = nil
                }
            }
        }) {
            SensorSelectionView(bluetoothManager: bluetoothManager, workout: workoutSelectionViewModel.workout, onComplete: { sensors, workout in
                self.connectedSensors = sensors
                self.workoutSelectionViewModel.workout = workout // Update ViewModel's workout if changed in SensorSelectionView
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
                Button(action: {
                    toggleBookmark()
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? .blue : .primary)
                }
            }
        }
        .onAppear {
            parseFile()
            checkBookmarkStatus()
        }
        .onChange(of: libraryViewModel.parsedWorkout) { newValue in
            if let workout = newValue {
                // Navigate to SessionView with the parsed workout
                navigationRouter.path.append(WorkoutSessionRoute(sensors: connectedSensors, workout: workout))
                // Reset for next time
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
            detailRow(label: "Units", value: course.units)
            detailRow(label: "Total Time", value: String(format: "%.1f mins", course.totalCourseTime()))
            detailRow(label: "Data Points", value: "\(course.course.count)")
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

    private func parseFile() {
        isLoading = true
        errorMessage = nil

        let fileName = file.data as? String ?? ""

        do {
            guard let url = try MRCParser.findMRCFile(named: fileName) else {
                errorMessage = "File not found."
                isLoading = false
                return
            }

            let content = try String(contentsOf: url, encoding: .utf8)
            if content.isEmpty {
                errorMessage = "File is empty or corrupted."
                isLoading = false
                return
            }

            let lines = content.components(separatedBy: .newlines)
            let parser = AssetFileParseUseCase(file: fileName, lines: lines)
            self.course = parser.invoke()
            if let course = self.course {
                self.workout = MRCWorkout(from: course)
            }
            if self.course == nil {
                errorMessage = "Failed to parse file content."
            }
        } catch {
            errorMessage = "File error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    
    private func checkBookmarkStatus() {
        let bookmarkedPaths = UserDefaults.standard.stringArray(forKey: "bookmarked_assets") ?? []
        isBookmarked = bookmarkedPaths.contains(file.data as? String ?? "")
    }

    private func toggleBookmark() {
        let path = file.data as? String ?? ""
        var bookmarkedPaths = UserDefaults.standard.stringArray(forKey: "bookmarked_assets") ?? []
        
        if isBookmarked {
            bookmarkedPaths.removeAll { $0 == path }
        } else {
            bookmarkedPaths.append(path)
        }
        
        UserDefaults.standard.set(bookmarkedPaths, forKey: "bookmarked_assets")
        isBookmarked.toggle()
    }
    
    private func playButton(_ course: MrcCourse) -> some View {
        Button(action: {
            print("LibraryDetailView: Play button clicked.")
            if isBluetoothUnavailable {
                showBluetoothExplanation = true
            } else {
                bluetoothManager.requestPermission()
                workoutSelectionViewModel.workout = MRCWorkout(from: course)
                workoutSelectionViewModel.showSensorSelection = true
                print("LibraryDetailView: Sensor selection requested for \(course.filename). Navigating back.")
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
    
    private func viewRawButton(_ course: MrcCourse) -> some View {
        Button(action: {
            print("LibraryDetailView: View Raw button clicked for \(course.filename)")
            do {
                if let url = try MRCParser.findMRCFile(named: course.filename) {
                    print("LibraryDetailView: Navigating to RawMRCView with path: \(url.path)")
                    navigationRouter.navigate(to: RawMRCViewRoute(filePath: url.path))
                }
            } catch {
                print("LibraryDetailView: Failed to resolve path for \(course.filename): \(error)")
            }
        }) {
            Text("View Raw")
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
        }
    }
}
