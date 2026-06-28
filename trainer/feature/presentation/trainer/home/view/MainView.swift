import SwiftUI
import libfitness

struct MainView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Binding var activeDeeplink: DeeplinkTarget?
    @State private var showMenu = false
    @State private var showProfile = false
    @State private var showSensorSelection = false
    @State private var connectedSensors: [MockSensor] = []
    @State private var showBluetoothExplanation = false
    @State private var showUnsupportedHardwareModal = false
    @State private var denialCount = 0
    @AppStorage("hasShownUnsupportedHardwareModal") private var hasShownUnsupportedHardwareModal = false
    @State private var showWorkoutSelectionModal = false
    @StateObject var workoutSelectionViewModel = WorkoutSelectionViewModel()

    private var isBluetoothUnavailable: Bool {
        if bluetoothManager.isMocking { return false }
        return bluetoothManager.permissionDenied || bluetoothManager.state == .poweredOff || bluetoothManager.isUnsupported
    }

    var body: some View {
        NavigationStack(path: $navigationRouter.path) {
            mainContent
                .environmentObject(workoutSelectionViewModel)
                .navigationDestination(for: String.self) { value in
                    navigationDestinations(for: value)
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .stravaAuth:
                        StravaAuthenticationView()
                    }
                }
                .navigationDestination(for: WorkoutSessionRoute.self) { route in
                    SessionView(sensors: route.sensors, course: route.course, workoutFile: route.workoutFile, workout: route.workout, bluetoothManager: bluetoothManager)
                }
                .toolbar {
                    toolbarItems
                }
                .modifier(MainViewSheetsAndCovers(
                    showMenu: $showMenu,
                    showProfile: $showProfile,
                    showSensorSelection: $showSensorSelection,
                    showBluetoothExplanation: $showBluetoothExplanation,
                    showUnsupportedHardwareModal: $showUnsupportedHardwareModal,
                    hasShownUnsupportedHardwareModal: $hasShownUnsupportedHardwareModal,
                    connectedSensors: $connectedSensors,
                    denialCount: $denialCount,
                    showWorkoutSelectionModal: $showWorkoutSelectionModal,
                    workoutSelectionViewModel: workoutSelectionViewModel
                ))
                .onChange(of: showProfile) { newValue in
                    if newValue {
                        navigationRouter.path.append("profile")
                        showProfile = false // Reset for next time
                    }
                }
                .onChange(of: activeDeeplink) { newValue in
                    if let newValue = newValue {
                        handleDeeplink(newValue)
                    }
                }
                .onChange(of: workoutSelectionViewModel.showSensorSelection) { shouldShow in
                    print("MainView: Detected workoutSelectionViewModel.showSensorSelection change to \(shouldShow)")
                    if shouldShow {
                        self.showSensorSelection = true
                        print("MainView: Successfully triggered SensorSelectionView fullScreenCover.")
                    }
                }
                .onChange(of: workoutSelectionViewModel.showLibrary) { shouldShow in
                    if shouldShow {
                        navigationRouter.path.append("library") // Navigate to library
                    }
                }
                .onAppear {
                    handleOnAppear()
                }
        }
    }

    private var mainContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 15) {
                WeeklyCalendarView()
                    .padding(.bottom, 5)
                sessionButton(geometry: geometry)
                calendarButton(geometry: geometry)
                libraryButton(geometry: geometry)
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    private func sessionButton(geometry: GeometryProxy) -> some View {
        Button(action: {
            if bluetoothManager.isUnsupported {
                // Already shown initial modal, banner is visible
                return
            }
            if isBluetoothUnavailable {
                showBluetoothExplanation = true
            } else {
                bluetoothManager.requestPermission()
                showWorkoutSelectionModal = true
            }
        }) {
            HStack {
                Text("Session")
                if isBluetoothUnavailable {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                }
            }
            .frame(minHeight: geometry.size.height * 0.12)
        }
        .buttonStyle(VividButtonStyle(backgroundColor: .blue, isEnabled: !isBluetoothUnavailable))
        .accessibilityIdentifier("sessionButton")
    }

    private func calendarButton(geometry: GeometryProxy) -> some View {
        Button(action: {
            navigationRouter.path.append("calendar")
        }) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                Text("Calendar")
            }
            .frame(minHeight: geometry.size.height * 0.12)
        }
        .buttonStyle(VividButtonStyle(backgroundColor: .green))
        .accessibilityIdentifier("calendarButton")
    }

    private func libraryButton(geometry: GeometryProxy) -> some View {
        Button(action: {
            navigationRouter.path.append("library")
        }) {
            HStack {
                Image(systemName: "books.vertical")
                    .font(.title2)
                Text("Library")
            }
            .frame(minHeight: geometry.size.height * 0.12)
        }
        .buttonStyle(VividButtonStyle(backgroundColor: .orange))
        .accessibilityIdentifier("libraryButton")
    }

    @ViewBuilder
    private func navigationDestinations(for value: String) -> some View {
        switch value {
        case "calendar":
            CalendarView()
        case "library":
            LibraryView()
                .environmentObject(workoutSelectionViewModel)
        case "profile":
            UserProfileView()
        default:
            EmptyView()
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                if isBluetoothUnavailable {
                    showBluetoothExplanation = true
                }
            }) {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .frame(width: 64, height: 48)
                    .foregroundColor(.blue)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                showMenu.toggle()
            }) {
                Image(systemName: "person.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .frame(width: 64, height: 48)
                    .foregroundColor(.blue)
            }
        }
    }

    private func handleDeeplink(_ target: DeeplinkTarget?) {
        if let target = target {
            switch target {
            case .main:
                // Clearing the navigation stack takes us back to MainContent
                navigationRouter.path.removeLast(navigationRouter.path.count)
            case .session(let workoutFile):
                var sensors: [MockSensor] = []
                if bluetoothManager.isMocking && connectedSensors.isEmpty {
                    // Provide default mock sensors for immediate session launch
                    sensors = [
                        MockSensor(name: "Mock HR", type: .HeartBeat, status: .Connected),
                        MockSensor(name: "Mock Power", type: .Power, status: .Connected)
                    ]
                    connectedSensors = sensors
                } else {
                    sensors = connectedSensors
                }
                navigationRouter.path.append(WorkoutSessionRoute(sensors: sensors, workoutFile: workoutFile))
            case .calendar: navigationRouter.path.append("calendar")
            case .library: navigationRouter.path.append("library")
            }
            // Clear the binding to prevent multiple triggers (e.g. if sheet dismiss causes re-appear)
            // But doing so in MainView itself should not trigger the 'clear stack' logic.
            DispatchQueue.main.async {
                self.activeDeeplink = nil
            }
        }
    }

    private func handleOnAppear() {
        if let target = activeDeeplink {
            handleDeeplink(target)
        }
        
        // Allow some time for BluetoothManager to initialize CBCentralManager and update state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if bluetoothManager.isUnsupported && !hasShownUnsupportedHardwareModal {
                showUnsupportedHardwareModal = true
            } else if bluetoothManager.permissionDenied {
                showBluetoothExplanation = true
            }
        }
    }
}

/// A ViewModifier to handle the various sheets and covers for MainView, 
/// further breaking down the complexity for the compiler.
struct MainViewSheetsAndCovers: ViewModifier {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var showMenu: Bool
    @Binding var showProfile: Bool
    @Binding var showSensorSelection: Bool
    @Binding var showBluetoothExplanation: Bool
    @Binding var showUnsupportedHardwareModal: Bool
    @Binding var hasShownUnsupportedHardwareModal: Bool
    @Binding var connectedSensors: [MockSensor]
    @Binding var denialCount: Int
    @Binding var showWorkoutSelectionModal: Bool
    @ObservedObject var workoutSelectionViewModel: WorkoutSelectionViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showMenu) {
                ProfileView(showProfile: $showProfile)
                    .environmentObject(navigationRouter)
            }
            .fullScreenCover(isPresented: $showSensorSelection, onDismiss: {
                if !connectedSensors.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigationRouter.path.append(WorkoutSessionRoute(sensors: connectedSensors, workout: workoutSelectionViewModel.workout))
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
                    denialCount += 1
                    if denialCount >= 2 {
                        print("App Terminating due to persistent Bluetooth denial")
                        exit(0)
                    }
                })
            }
            .fullScreenCover(isPresented: $showUnsupportedHardwareModal) {
                BluetoothHardwareUnsupportedView(onDismiss: {
                    showUnsupportedHardwareModal = false
                    hasShownUnsupportedHardwareModal = true
                })
            }
            .sheet(isPresented: $showWorkoutSelectionModal) {
                WorkoutSelectionModal(viewModel: workoutSelectionViewModel)
                    .onAppear {
                        workoutSelectionViewModel.reset()
                    }
            }
            .alert("Workout Selection Error", isPresented: Binding<Bool>(
                get: { workoutSelectionViewModel.workoutSelectionError != nil },
                set: { _ in workoutSelectionViewModel.workoutSelectionError = nil }
            )) {
                Button("OK") { }
            } message: {
                Text(workoutSelectionViewModel.workoutSelectionError ?? "An unknown error occurred.")
            }
    }
}

#Preview {
    MainView(activeDeeplink: .constant(nil))
        .environmentObject(BluetoothManager())
        .environmentObject(NavigationRouter())
}
