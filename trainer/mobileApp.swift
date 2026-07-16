import SwiftUI
import CoreData
import libfitness

@main
struct mobileApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var authService = AuthenticationService()
    @StateObject var bluetoothManager = BluetoothManager()
    @StateObject var navigationRouter = NavigationRouter()
    @State private var showSplash = true
    @State private var deeplinkURL: URL?
    @State private var activeDeeplink: DeeplinkTarget?
    @State private var showDeeplinkSimulationSheet = false

    init() {
        let fitProcessor = IOSFitFileProcessor()
        InitializerKt.initializeApp(processor: fitProcessor, launcher: DefaultLauncher())
        
        // Bypass splash screen during UI testing
        let args = ProcessInfo.processInfo.arguments
        _showSplash = State(initialValue: !args.contains("--uitesting"))
        
        if args.contains("--clear-defaults") {
            UserDefaults.standard.removeObject(forKey: "hasShownUnsupportedHardwareModal")
        }
        
        // Handle internal deeplink for UI testing if provided
        if let deeplinkIndex = args.firstIndex(of: "--deeplink"), deeplinkIndex + 1 < args.count {
            let urlString = args[deeplinkIndex + 1]
            print("UI Testing: Received internal deeplink: \(urlString)")
            if let url = URL(string: urlString) {
                _deeplinkURL = State(initialValue: url)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authService.isAuthenticated {
                    MainView(activeDeeplink: $activeDeeplink)
                        .environmentObject(navigationRouter)
                } else {
                    LoginView()
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(authService)
            .environmentObject(bluetoothManager)
            .onOpenURL { url in
                handleDeeplink(url)
            }
            .sheet(isPresented: $showDeeplinkSimulationSheet) {
                DeeplinkSimulationSheet(options: [
                    DeeplinkOption(label: "Main View", url: URL(string: "skjline://main")),
                    DeeplinkOption(label: "Session View (Random)", url: URL(string: "skjline://session?mock=true")),
                    DeeplinkOption(label: "Session (3-Min Demo)", url: URL(string: "skjline://session/trainer/training/beginner/training-3min.mrc?mock=true"))
                ]) { option in
                    if let url = option.url {
                        handleDeeplink(url)
                    }
                }
            }
            .onAppear {
                // Process initial deeplink if it was passed via launch arguments
                if let url = deeplinkURL {
                    handleDeeplink(url)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("onOpenURL"))) { notification in
                if let url = notification.object as? URL {
                    handleDeeplink(url)
                }
            }
            .onChange(of: authService.isAuthenticated) { newValue in
                if newValue, let url = deeplinkURL {
                    handleDeeplink(url)
                }
            }
            .overlay {
                if showSplash {
                    SplashScreenView(showSplash: $showSplash)
                }
            }
        }
    }

    private func handleDeeplink(_ url: URL) {
        // Small delay to ensure the app is ready to handle state changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("UI Testing: Processing deeplink: \(url)")
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return
            }

            let scheme = url.scheme
            let host = components.host ?? ""
            let path = components.path
            
            // Normalize path: for skjline://, host is usually the action. For http://, path is the action.
            let normalizedPath = (scheme == "skjline") ? "/\(host)\(path)" : path
            print("UI Testing: Normalized path: \(normalizedPath)")
            
            if normalizedPath == "/simulate" {
                print("UI Testing: Showing simulation sheet")
                DispatchQueue.main.async {
                    self.showDeeplinkSimulationSheet = true
                }
                self.deeplinkURL = nil
                return
            }

            // Parse query parameters
            let queryItems = components.queryItems ?? []
            if let mock = queryItems.first(where: { $0.name == "mock" })?.value, mock == "true" {
                print("UI Testing: Mocking enabled via deeplink")
                self.bluetoothManager.isMocking = true
            }
            
            let sessionId = queryItems.first(where: { $0.name == "sessionId" })?.value
            
            if authService.isAuthenticated {
                print("UI Testing: Authenticated, setting activeDeeplink for path: \(normalizedPath)")
                DispatchQueue.main.async {
                    if normalizedPath == "/main" {
                        self.activeDeeplink = .main
                    } else if normalizedPath.starts(with: "/session") {
                        // Check for skjline://session/trainer/path/to/file.mrc
                        if normalizedPath.starts(with: "/session/trainer/") {
                            let filename = normalizedPath.replacingOccurrences(of: "/session/trainer/", with: "")
                            if !filename.isEmpty {
                                self.activeDeeplink = .session(workoutFile: filename, sessionId: sessionId)
                            } else {
                                self.activeDeeplink = .session(workoutFile: nil, sessionId: sessionId)
                            }
                        } else {
                            self.activeDeeplink = .session(workoutFile: nil, sessionId: sessionId)
                        }
                    } else if normalizedPath == "/calendar" {
                        self.activeDeeplink = .calendar
                    } else if normalizedPath == "/library" {
                        self.activeDeeplink = .library
                    } else {
                        print("UI Testing: Unknown path: \(normalizedPath)")
                    }
                    self.deeplinkURL = nil // Reset after processing
                }
            } else {
                // For simulation purposes, if we get a direct deeplink and not authenticated, 
                // we can choose to force authenticate or wait. 
                // The original alert did force authenticate, so let's do it if it's a simulation URL.
                if scheme == "skjline" {
                    print("UI Testing: Force authenticating for simulation deeplink")
                    authService.forceAuthenticate(username: "demo@skjline.mobile")
                    deeplinkURL = url // Store to process after auth completes
                } else {
                    // Store the deeplink and wait for authentication
                    deeplinkURL = url
                }
            }
        }
    }
}
