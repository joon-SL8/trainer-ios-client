import Foundation
import libfitness

extension PacketType {
    func toSensorType() -> SensorType? {
        switch self {
        case .hrdata:
            return .HeartBeat
        case .power:
            return .Power
        case .speed:
            return .Speed
        case .cadence:
            return .Cadence
        default:
            return nil
        }
    }
}
