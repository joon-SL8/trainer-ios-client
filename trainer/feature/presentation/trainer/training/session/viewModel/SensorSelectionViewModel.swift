import SwiftUI
import Combine

@MainActor
class SensorSelectionViewModel: ObservableObject {
    @Published var sensors: [MockSensor] = []
    @Published var isScanning: Bool = false
    @Published var connectionStatus: String?
    @Published var errorMessage: String?
    @Published var showBluetoothSettingsAlert: Bool = false
    @Published var workout: MRCWorkout? // New property to hold the workout
    
    private let fitnessMachineServiceUUID = "1826"
    
    var fitnessMachineSensors: [MockSensor] {
        sensors.filter { sensor in
            sensor.bluetoothSensor?.advertisedServiceUUIDs.contains(fitnessMachineServiceUUID) ?? false
        }
    }
    
    var otherSensors: [MockSensor] {
        sensors.filter { sensor in
            !(sensor.bluetoothSensor?.advertisedServiceUUIDs.contains(fitnessMachineServiceUUID) ?? false)
        }
    }
    
    var canStartTraining: Bool {
        fitnessMachineSensors.contains { $0.status == .Connected }
    }
    
    var hasConnectedSensors: Bool {
        sensors.contains { $0.status == .Connected }
    }
    
    private var scanTask: Task<Void, Never>?
    private var scanFlowTask: Task<Void, Never>?
    private var connectionTasks: [Task<Void, Never>] = []
    private let bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()

    init(bluetoothManager: BluetoothManager, workout: MRCWorkout?) {
        self.bluetoothManager = bluetoothManager
        self.workout = workout
        
        // Observe bluetooth manager state for permissions
        bluetoothManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                print("SensorSelectionViewModel: Bluetooth state updated to \(state.rawValue)")
                
                if state == .unsupported {
                    #if targetEnvironment(simulator)
                    // In simulator, we just log it and rely on startSimulation() to finish
                    print("SensorSelectionViewModel: Running in simulator, ignoring unsupported state for simulation.")
                    #else
                    print("SensorSelectionViewModel: Bluetooth unsupported. Setting errorMessage.")
                    self.errorMessage = "Bluetooth is not supported on this device. Please check your hardware."
                    self.isScanning = false
                    #endif
                    return
                }
                
                if state == .unauthorized || state == .poweredOff {
                    print("SensorSelectionViewModel: Bluetooth unauthorized or powered off. Showing settings alert.")
                    self.showBluetoothSettingsAlert = true
                    self.isScanning = false
                }
            }
            .store(in: &cancellables)

        // Observe discovered sensors
        bluetoothManager.$discoveredSensors
            .receive(on: RunLoop.main)
            .sink { [weak self] sensors in
                guard let self = self else { return }
                print("SensorSelectionViewModel: Discovered sensors updated. Count: \(sensors.count)")
                self.updateDiscoveredSensors(sensors)
                print("SensorSelectionViewModel: Current sensors state: \(self.sensors.map { "\($0.name): \($0.status)" }.joined(separator: ", ") ?? "N/A")")
            }
            .store(in: &cancellables)
            
        // Observe connection status
        bluetoothManager.$connectionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] statusMap in
                guard let self = self else { return }
                print("SensorSelectionViewModel: Connection status map updated: \(statusMap.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
                for (id, status) in statusMap {
                    if let index = self.sensors.firstIndex(where: { $0.id == id }) {
                        self.sensors[index].status = self.mapStatus(status)
                        print("SensorSelectionViewModel: Sensor \(self.sensors[index].name) status changed to \(self.sensors[index].status.rawValue)")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateDiscoveredSensors(_ newSensors: [BluetoothSensor]) {
        print("SensorSelectionViewModel: updateDiscoveredSensors called with \(newSensors.count) new sensors.")
        for sensor in newSensors {
            if let index = sensors.firstIndex(where: { $0.id == sensor.id }) {
                print("SensorSelectionViewModel: Updating existing sensor: \(sensor.name)")
                // Update existing sensor metadata if needed, but preserve status
                sensors[index].bluetoothSensor = sensor
            } else {
                print("SensorSelectionViewModel: Adding new sensor: \(sensor.name)")
                // Add new sensor
                let newMock = MockSensor(
                    id: sensor.id,
                    name: sensor.name,
                    type: sensor.type == .HeartBeat ? .HeartBeat : .Power,
                    status: .Discovered,
                    bluetoothSensor: sensor
                )
                sensors.append(newMock)
            }
        }
    }
    
    private func mapStatus(_ status: ConnectionStatus) -> Status {
        switch status {
        case .disconnected: return .Disconnected
        case .connecting: return .Connecting
        case .connected: return .Connected
        }
    }
    
    var selectedSensors: [MockSensor] {
        sensors.filter { $0.status == .Connected }
    }
    
    func disconnectAll() {
        bluetoothManager.disconnectAll()
    }
    
    deinit {
        scanTask?.cancel()
        scanFlowTask?.cancel()
        connectionTasks.forEach { $0.cancel() }
        
        let bluetoothManager = self.bluetoothManager
        Task {
            bluetoothManager.stopScanning()
            bluetoothManager.disconnectAll()
        }
    }
    
    func startScanning() {
        print("SensorSelectionViewModel: startScanning() invoked.")
        guard !isScanning else { 
            print("SensorSelectionViewModel: Already scanning, skipping.")
            return 
        }
        
        #if !targetEnvironment(simulator)
        print("SensorSelectionViewModel: Checking hardware state: \(bluetoothManager.state.rawValue)")
        if bluetoothManager.state == .unauthorized || bluetoothManager.state == .poweredOff {
            print("SensorSelectionViewModel: Bluetooth unavailable, showing alert.")
            showBluetoothSettingsAlert = true
            return
        }
        
        if bluetoothManager.state == .unsupported {
            print("SensorSelectionViewModel: Bluetooth unsupported.")
            errorMessage = "Bluetooth is not supported on this device. Please check your hardware."
            return
        }
        #endif
        
        print("SensorSelectionViewModel: Scanning process started.")
        isScanning = true
        sensors = []
        errorMessage = nil
        
        #if targetEnvironment(simulator)
        print("SensorSelectionViewModel: Simulator detected, starting simulation.")
        startSimulation()
        #else
        print("SensorSelectionViewModel: Triggering BluetoothManager scan.")
        // Use filtered scan by default as requested
        bluetoothManager.debugUnfilteredScan = false 
        bluetoothManager.startScanning()
        
        // Auto-stop scanning after 30 seconds if nothing found
        Task {
            print("SensorSelectionViewModel: Scan timeout task started (30s).")
            try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
            if self.isScanning && self.sensors.isEmpty {
                print("SensorSelectionViewModel: Scan timeout reached, no sensors found.")
                self.errorMessage = "No sensors found. Ensure your devices are in pairing mode."
                self.stopScanning()
            }
        }
        #endif
    }
    
    private func startSimulation() {
        scanTask?.cancel()
        scanTask = Task {
            // Simulate searching state
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            
            // Mock sensor discovery
            let mockData: [(String, SensorType)] = [
                ("H6 Heart Rate", .HeartBeat),
                ("Kickr Bike", .Power),
                ("Polar OH1", .HeartBeat)
            ]
            
            for data in mockData {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                let newSensor = MockSensor(name: data.0, type: data.1, status: .Discovered)
                sensors.append(newSensor)
            }
            
            isScanning = false
            
            if sensors.isEmpty {
                errorMessage = "No sensors found. Please ensure your device is on."
            }
        }
    }
    
    func connect(to sensor: MockSensor) {
        guard let index = sensors.firstIndex(where: { $0.id == sensor.id }) else { return }
        
        sensors[index].status = .Connecting
        connectionStatus = "Connecting to \(sensor.name)..."
        
        #if targetEnvironment(simulator)
        Task {
            try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
            sensors[index].status = .Connected
            connectionStatus = "\(sensor.name) Connected"
        }
        #else
        if let bluetoothSensor = sensor.bluetoothSensor {
            print("Connecting to sensor: \(sensor.name)")
            bluetoothManager.connect(to: bluetoothSensor.peripheral)
        }
        #endif
    }
    
    func stopScanning() {
        #if targetEnvironment(simulator)
        scanTask?.cancel()
        #else
        bluetoothManager.stopScanning()
        #endif
        isScanning = false
    }
}
