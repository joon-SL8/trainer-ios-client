import Foundation
import CoreBluetooth
import Combine
import libfitness

public enum SensorType {
    case HeartBeat
    case Speed
    case Cadence
    case Power
}

public enum Status: Int {
    case Discovered
    case Connecting
    case Connected
    case Disconnected
}

public struct BluetoothSensor: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let peripheral: CBPeripheral
    public var status: Status = .Discovered
    public var type: SensorType = .HeartBeat
    public var advertisedServiceUUIDs: [String] = []
    
    public init(id: UUID, name: String, peripheral: CBPeripheral, status: Status = .Discovered, type: SensorType = .HeartBeat, advertisedServiceUUIDs: [String] = []) {
        self.id = id
        self.name = name
        self.peripheral = peripheral
        self.status = status
        self.type = type
        self.advertisedServiceUUIDs = advertisedServiceUUIDs
    }
    
    public static func == (lhs: BluetoothSensor, rhs: BluetoothSensor) -> Bool {
        lhs.id == rhs.id
    }
}

enum BluetoothState: String {
    case unknown = "Unknown"
    case resetting = "Resetting"
    case unsupported = "Unsupported"
    case unauthorized = "Unauthorized"
    case poweredOff = "Powered Off"
    case poweredOn = "Powered On"
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
}

public class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var state: BluetoothState = .unknown
    @Published public var permissionDenied: Bool = false
    @Published public var isUnsupported: Bool = false
    @Published public var isMocking: Bool = false
    @Published public var discoveredSensors: [BluetoothSensor] = []
    @Published var connectionStatus: [UUID: ConnectionStatus] = [:]
    @Published public var debugUnfilteredScan: Bool = false
    
    public let dataPublisher = PassthroughSubject<(UUID, CBUUID, Data), Never>()
    
    private var centralManager: CBCentralManager?
    private let serviceTags: [String] = BLEDeviceUtil.companion.serviceTags
    private var isPendingScan: Bool = false
    
    public let heartRateServiceUUID = CBUUID(string: "180D") // Heart Rate Service
    public let heartRateMeasurementCharacteristicUUID = CBUUID(string: "2A37") // Heart Rate Measurement Characteristic
    public let cscServiceUUID = CBUUID(string: "1816") // Cycling Speed and Cadence Service
    public let cscMeasurementCharacteristicUUID = CBUUID(string: "2A5B") // CSC Measurement Characteristic
    public let cpServiceUUID = CBUUID(string: "1818") // Cycling Power Service
    public let cpMeasurementCharacteristicUUID = CBUUID(string: "2A63") // Cycling Power Measurement Characteristic

    private var serviceUUIDs: [CBUUID] {
        var uuids: [CBUUID] = [heartRateServiceUUID, cscServiceUUID, cpServiceUUID] // Include new services
        
        serviceTags.compactMap { tag in
            // Parse 16-bit UUID from 128-bit string as requested: char[4..7]
            // Example: 0000180D-0000-1000-8000-00805f9b34fb -> 180D
            if tag.count >= 8 {
                let startIndex = tag.index(tag.startIndex, offsetBy: 4)
                let endIndex = tag.index(tag.startIndex, offsetBy: 8)
                let shortUUID = String(tag[startIndex..<endIndex])
                print("BluetoothManager: Parsed short UUID \(shortUUID) from \(tag)")
                return CBUUID(string: shortUUID)
            }
            // Fallback to full string if too short
            return try? CBUUID(string: tag)
        }.forEach { uuids.append($0) }
        
        return uuids
    }
    
    override init() {
        super.init()
        
        // Handle UI testing mocks
        if ProcessInfo.processInfo.arguments.contains("--mock-bluetooth-denied") {
            self.state = .unauthorized
            self.permissionDenied = true
            return
        }
        
        if ProcessInfo.processInfo.arguments.contains("--mock-bluetooth-unsupported") {
            self.state = .unsupported
            self.isUnsupported = true
            return
        }

        // Initialize central manager without showing the prompt immediately
        // showPowerAlert is false because we handle the UI ourselves
        let options: [String: Any] = [
            CBCentralManagerOptionRestoreIdentifierKey: "com.skjline.trainer.BluetoothManager",
            CBCentralManagerOptionShowPowerAlertKey: false
        ]
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: options)

    }
    
    func requestPermission() {
        // In iOS, initializing CBCentralManager with a delegate triggers the permission prompt
        // if it hasn't been shown yet. If it was already denied, we can't trigger it again.
        if centralManager == nil {
            let options: [String: Any] = [
                CBCentralManagerOptionRestoreIdentifierKey: "com.skjline.trainer.BluetoothManager",
                CBCentralManagerOptionShowPowerAlertKey: false
            ]
            centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
        }
    }

    func startScanning() {
        print("BluetoothManager: startScanning() called.")
        guard let central = centralManager else {
            print("BluetoothManager: CentralManager is nil, cannot scan.")
            return
        }
        
        guard central.state == .poweredOn else {
            print("BluetoothManager: CBCentralManager state is \(central.state.rawValue), not poweredOn. Setting isPendingScan = true.")
            isPendingScan = true
            return
        }
        
        let scanUUIDs = debugUnfilteredScan ? nil : serviceUUIDs
        print("BluetoothManager: SCAN INITIATED. Services: \(scanUUIDs?.map { $0.uuidString } ?? ["ALL (Unfiltered)"])")
        central.scanForPeripherals(withServices: scanUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        isPendingScan = false
    }

    func stopScanning() {
        print("BluetoothManager: Stopping scan")
        isPendingScan = false
        if centralManager?.state == .poweredOn {
            centralManager?.stopScan()
        }
    }

    deinit {
        stopScanning()
    }

    
    // MARK: - CBCentralManagerDelegate

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // Handle restoration of central manager state if needed.
        // For now, this satisfies the requirement to prevent crashes.
        print("BluetoothManager: State being restored: \(dict)")
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("BluetoothManager: Received state update: \(central.state.rawValue)")
        switch central.state {
        case .unknown:
            state = .unknown
        case .resetting:
            state = .resetting
        case .unsupported:
            #if targetEnvironment(simulator)
            print("BluetoothManager: Bluetooth is unsupported in the simulator. This is expected behavior; use simulation/mocking for testing.")
            #else
            print("BluetoothManager: Critical error, Bluetooth is unsupported on this hardware. This device may not support Bluetooth Low Energy.")
            #endif
            state = .unsupported
            isUnsupported = true
        case .unauthorized:
            state = .unauthorized
            permissionDenied = true
        case .poweredOff:
            state = .poweredOff
        case .poweredOn:
            state = .poweredOn
            permissionDenied = false
            if isPendingScan {
                print("BluetoothManager: State became poweredOn, triggering pending scan.")
                startScanning()
            }
        @unknown default:
            state = .unknown
        }
        
        print("Bluetooth State Updated: \(state.rawValue)")
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("BluetoothManager: DISCOVERED: \(peripheral.name ?? "Unknown Device") (\(peripheral.identifier)) RSSI: \(RSSI)")
        
        let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map { $0.uuidString } ?? []
        
        if !discoveredSensors.contains(where: { $0.peripheral == peripheral }) {
            let sensor = BluetoothSensor(
                id: peripheral.identifier,
                name: peripheral.name ?? "Unknown Device",
                peripheral: peripheral,
                advertisedServiceUUIDs: serviceUUIDs
            )
            DispatchQueue.main.async {
                self.discoveredSensors.append(sensor)
            }
        }
    }

    func connect(to peripheral: CBPeripheral) {
        print("BluetoothManager: Connecting to peripheral: \(peripheral.name ?? "Unknown")")
        connectionStatus[peripheral.identifier] = .connecting
        centralManager?.connect(peripheral, options: nil)
    }

    func disconnect(from peripheral: CBPeripheral) {
        print("BluetoothManager: Disconnecting from peripheral: \(peripheral.name ?? "Unknown")")
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    // MARK: - CBCentralManagerDelegate (Connection)

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("BluetoothManager: Connected to: \(peripheral.name ?? "Unknown")")
        connectionStatus[peripheral.identifier] = .connected
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("BluetoothManager: Failed to connect to: \(peripheral.name ?? "Unknown"), error: \(String(describing: error))")
        connectionStatus[peripheral.identifier] = .disconnected
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("BluetoothManager: Disconnected from: \(peripheral.name ?? "Unknown"), error: \(String(describing: error))")
        connectionStatus[peripheral.identifier] = .disconnected
    }

    // MARK: - CBPeripheralDelegate

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            // If it's a known service, specifically discover its measurement characteristic
            if service.uuid == heartRateServiceUUID {
                print("BluetoothManager: Discovered Heart Rate Service, discovering Heart Rate Measurement Characteristic.")
                peripheral.discoverCharacteristics([heartRateMeasurementCharacteristicUUID], for: service)
            } else if service.uuid == cscServiceUUID {
                print("BluetoothManager: Discovered CSC Service, discovering CSC Measurement Characteristic.")
                peripheral.discoverCharacteristics([cscMeasurementCharacteristicUUID], for: service)
            } else if service.uuid == cpServiceUUID {
                print("BluetoothManager: Discovered Cycling Power Service, discovering CP Measurement Characteristic.")
                peripheral.discoverCharacteristics([cpMeasurementCharacteristicUUID], for: service)
            } else {
                // Discover characteristics for other services
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            // Check for known characteristics and enable notifications
            if characteristic.uuid == heartRateMeasurementCharacteristicUUID ||
               characteristic.uuid == cscMeasurementCharacteristicUUID ||
               characteristic.uuid == cpMeasurementCharacteristicUUID {
                
                if characteristic.properties.contains(.notify) {
                    print("BluetoothManager: Enabling notifications for characteristic: \(characteristic.uuid.uuidString)")
                    peripheral.setNotifyValue(true, for: characteristic)
                } else {
                    print("BluetoothManager: Characteristic \(characteristic.uuid.uuidString) does not support notifications.")
                }
            } else if characteristic.properties.contains(.notify) {
                // For other characteristics, if they support notify, set it.
                // This preserves existing behavior for other sensors.
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            if characteristic.uuid == heartRateMeasurementCharacteristicUUID {
                print("BluetoothManager: Received Heart Rate data raw: \(data.map { String(format: "%02hhx", $0) }.joined())")
                // Publish the raw data directly to allow Orchestrator to parse it correctly
                dataPublisher.send((peripheral.identifier, characteristic.uuid, data))
            } else {
                // For CSC and CP data, or other data, publish the raw data along with the characteristic UUID
                dataPublisher.send((peripheral.identifier, characteristic.uuid, data))
            }
        }
    }
}
