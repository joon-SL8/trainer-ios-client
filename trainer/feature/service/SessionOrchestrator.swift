import Foundation
import Combine
import libfitness
import CoreBluetooth

public class SessionOrchestrator: ObservableObject {
    private let bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var sessionState: String = "Idle"
    @Published public var sensorData: [UUID: String] = [:] // Placeholder for sensor data
    @Published public var currentHeartRateContent: HeartRateContent?
    @Published public var cscData: CSCData?
    @Published public var cyclingPowerPacket: CyclingPowerMeasurementPacket?
    
    private var lastTargetPower: Int?
    private var observedSensors = Set<UUID>()

    private(set) public var timer = SessionTimeDataTimer()

    public init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
        
        // Observe connection changes
        bluetoothManager.$connectionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] statusMap in
                guard let self = self else { return }
                for (id, status) in statusMap {
                    if status == .connected {
                        self.startDataCollection(for: id)
                    } else {
                        self.stopDataCollection(for: id)
                    }
                }
            }
            .store(in: &cancellables)
            
        // Observe data stream
        bluetoothManager.dataPublisher
            .sink { [weak self] (sensorId, characteristicUUID, data) in
                guard let self = self else { return }
                
                if characteristicUUID == self.bluetoothManager.heartRateMeasurementCharacteristicUUID {
                    // Heart Rate
                    if let heartRate = BluetoothDataParser.parseHeartRate(from: data) {
                        self.sensorData[sensorId] = String(heartRate)
                        let heartRateContent = HeartRateContent(content: HeartRatePacket(hrData: Int32(heartRate)))
                        self.currentHeartRateContent = heartRateContent
                    } else {
                        print("SessionOrchestrator: Failed to parse Heart Rate data. Data count: \(data.count)")
                    }
                } else if characteristicUUID == self.bluetoothManager.cscMeasurementCharacteristicUUID {
                    // CSC
                    if let cscData = BluetoothDataParser.parseCSC(from: data) {
                        print("SessionOrchestrator: Received CSC data from \(sensorId)")
                        self.cscData = cscData
                        self.sensorData[sensorId] = "CSC Data Received"
                    }
                } else if characteristicUUID == self.bluetoothManager.cpMeasurementCharacteristicUUID {
                    // Cycling Power
                    let byteArray = data.toByteArray() // Assuming extension exists
                    let cpPacket = CyclingPowerMeasurementPacket.companion.fromPayload(data: byteArray)
                    self.cyclingPowerPacket = cpPacket
                    self.sensorData[sensorId] = "CP: \(cpPacket.powerLevel) W"
                } else {
                    let hexString = data.map { String(format: "%02hhx", $0) }.joined()
                    self.sensorData[sensorId] = hexString
                }
            }
            .store(in: &cancellables)
    }

    private func sendFMCPCommand(_ command: Data) {
        for (_, peripheral) in bluetoothManager.getConnectedPeripherals() {
            bluetoothManager.writeToFMCP(data: command, for: peripheral)
        }
    }

    public func requestControl() {
        print("SessionOrchestrator: Requesting control from FMCP device.")
        sendFMCPCommand(PowerControlCommands.getRequestControlCommand())
    }

    public func updateTargetPower(power: Int) {
        if lastTargetPower != power {
            print("SessionOrchestrator: Updating target power. Old: \(lastTargetPower ?? 0) W, New: \(power) W")
            lastTargetPower = power
            sendFMCPCommand(PowerControlCommands.getSetTargetPowerCommand(power: power))
        }
    }

    private func startDataCollection(for sensorId: UUID) {
        if observedSensors.contains(sensorId) {
            print("SessionOrchestrator: Skipping redundant data collection for \(sensorId)")
            return
        }
        print("SessionOrchestrator: Start data collection for \(sensorId)")
        observedSensors.insert(sensorId)
    }
    
    private func stopDataCollection(for sensorId: UUID) {
        if !observedSensors.contains(sensorId) {
            return
        }
        print("SessionOrchestrator: Stop data collection for \(sensorId)")
        observedSensors.remove(sensorId)
    }
    
    public func setCourseData(course: MrcCourse) {
        timer.request(action: SetCourse(course: course))
    }

    public func startSession(with workout: MRCWorkout) {
        sessionState = "Active"
        timer.request(action: Start.shared)
        sendFMCPCommand(PowerControlCommands.getStartCommand())
    }
    
    public func pauseSession() {
        sessionState = "Paused"
        timer.request(action: Pause.shared)
        sendFMCPCommand(PowerControlCommands.getStopCommand())
    }

    public func resumeSession() {
        sessionState = "Active"
        timer.request(action: Resume.shared)
        sendFMCPCommand(PowerControlCommands.getStartCommand())
    }

    public func stopSession() {
        sessionState = "Idle"
        timer.request(action: Stop.shared)
        updateTargetPower(power: 0)
        sendFMCPCommand(PowerControlCommands.getStopCommand())
    }
    
    public func cleanup() {
        print("SessionOrchestrator: Cleaning up session, disconnecting all sensors.")
        bluetoothManager.disconnectAll()
    }
    
}
