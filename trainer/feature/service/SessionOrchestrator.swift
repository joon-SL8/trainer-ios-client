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
    @Published public var cyclingPowerData: CyclingPowerData?
    
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
                        print("SessionOrchestrator: Received Heart Rate: \(heartRate) BPM")
                        self.sensorData[sensorId] = String(heartRate)
                        let heartRateContent = HeartRateContent(content: HeartRatePacket(hrData: Int32(heartRate)))
                        self.currentHeartRateContent = heartRateContent
                    } else {
                        print("SessionOrchestrator: Failed to parse Heart Rate data. Data count: \(data.count)")
                    }
                } else if characteristicUUID == self.bluetoothManager.cscMeasurementCharacteristicUUID {
                    // CSC
                    print("SessionOrchestrator: Matched CSC characteristic.")
                    if let cscData = BluetoothDataParser.parseCSC(from: data) {
                        print("SessionOrchestrator: Received CSC data from \(sensorId)")
                        self.cscData = cscData
                        self.sensorData[sensorId] = "CSC Data Received"
                    }
                } else if characteristicUUID == self.bluetoothManager.cpMeasurementCharacteristicUUID {
                    // Cycling Power
                    print("SessionOrchestrator: Matched Cycling Power characteristic.")
                    if let cpData = BluetoothDataParser.parseCyclingPower(from: data) {
                        print("SessionOrchestrator: Received CP data from \(sensorId)")
                        self.cyclingPowerData = cpData
                        self.sensorData[sensorId] = "CP Data: \(cpData.instantaneousPower) W"
                    }
                } else {
                    let hexString = data.map { String(format: "%02hhx", $0) }.joined()
                    print("SessionOrchestrator: Received unknown data from \(sensorId) (\(characteristicUUID.uuidString)): \(hexString)")
                    self.sensorData[sensorId] = hexString
                }
            }
            .store(in: &cancellables)
    }

    private func startDataCollection(for sensorId: UUID) {
        print("SessionOrchestrator: Start data collection for \(sensorId)")
        // In a real implementation, you would call methods on the peripheral here.
    }
    
    private func stopDataCollection(for sensorId: UUID) {
        print("SessionOrchestrator: Stop data collection for \(sensorId)")
    }
    
    public func setCourseData(course: MrcCourse) {
        timer.request(action: SetCourse(course: course))
    }

    public func startSession(with workout: MRCWorkout) {
        sessionState = "Active"
        timer.request(action: Start.shared)
    }
    
    public func pauseSession() {
        sessionState = "Paused"
        timer.request(action: Pause.shared)
    }
    
    public func stopSession() {
        sessionState = "Idle"
        timer.request(action: Stop.shared)
    }
    
    public func cleanup() {
        print("SessionOrchestrator: Cleaning up session, disconnecting all sensors.")
        bluetoothManager.disconnectAll()
    }
    
}
