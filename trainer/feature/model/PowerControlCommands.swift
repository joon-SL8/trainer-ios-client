import Foundation
import CoreBluetooth

public struct PowerControlCommands {
    public static func getRequestControlCommand() -> Data {
        // 0x01: Reset
        return Data([0x00])
    }

    public static func getResetCommand() -> Data {
        // 0x01: Reset
        return Data([0x01])
    }

    public static func getStartCommand() -> Data {
        // Implement based on Fitness Machine Control Point protocol
        // 0x07: Start or Resume
        return Data([0x07])
    }
    
    public static func getStopCommand() -> Data {
        // 0x08: Stop or Pause
        return Data([0x08])
    }
    
    public static func getSetTargetPowerCommand(power: Int) -> Data {
        // 0x05: Set Power
        // Command [0x05, Power_LSB, Power_MSB]
        var data = Data([0x05])
        data.append(contentsOf: [UInt8(power & 0xFF), UInt8((power >> 8) & 0xFF)])
        return data
    }
}
