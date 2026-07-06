import Foundation
import CoreBluetooth

public struct PowerControlCommands {
    public static func getStartCommand() -> Data {
        // Implement based on Fitness Machine Control Point protocol
        // 0x07: Start
        return Data([0x07])
    }
    
    public static func getPauseCommand() -> Data {
        // 0x08: Pause
        return Data([0x08])
    }
    
    public static func getStopCommand() -> Data {
        // 0x05: Stop
        return Data([0x05])
    }
    
    public static func getSetTargetPowerCommand(power: Int) -> Data {
        // 0x01: Set Power
        // Command [0x01, Power_LSB, Power_MSB]
        var data = Data([0x01])
        data.append(contentsOf: [UInt8(power & 0xFF), UInt8((power >> 8) & 0xFF)])
        return data
    }
}
