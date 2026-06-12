import Foundation
import CoreBluetooth

public struct MockSensor: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let type: SensorType
    public var status: Status
    public var bluetoothSensor: BluetoothSensor?
    
    public init(id: UUID = UUID(), name: String, type: SensorType, status: Status = .Discovered, bluetoothSensor: BluetoothSensor? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.bluetoothSensor = bluetoothSensor
    }
    
    public static func == (lhs: MockSensor, rhs: MockSensor) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
