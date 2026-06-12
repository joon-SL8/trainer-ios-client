//
//  BluetoothDataParser.swift
//  trainer
//
//  Created by mjlee-air on 2026/06/08.
//

import Foundation

public struct CSCData {
    public let cumulativeWheelRevolutions: UInt32?
    public let lastWheelEventTime: UInt16?
    public let cumulativeCrankRevolutions: UInt16?
    public let lastCrankEventTime: UInt16?
}

public struct CyclingPowerData {
    public let instantaneousPower: Int16
    public let pedalPowerBalance: UInt8?
    public let accumulatedTorque: UInt16?
    public let cumulativeWheelRevolutions: UInt32?
    public let lastWheelEventTime: UInt16?
    public let cumulativeCrankRevolutions: UInt16?
    public let lastCrankEventTime: UInt16?
    public let accumulatedEnergy: UInt16?
}

public class BluetoothDataParser {
    
    /// Parses Heart Rate Measurement characteristic data (UUID 2A37).
    ///
    /// The format of the Heart Rate Measurement characteristic value is defined as:
    /// - Flags (1 byte)
    /// - Heart Rate Value (1 or 2 bytes, depending on Flags)
    /// - Optional: Energy Expended (2 bytes)
    /// - Optional: RR-Interval (multiple 2-byte values)
    ///
    /// This function extracts the Heart Rate Value.
    ///
    /// - Parameter data: The raw data received from the 2A37 characteristic.
    /// - Returns: The heart rate value as an Int, or nil if parsing fails.
    public static func parseHeartRate(from data: Data) -> Int? {
        guard data.count >= 1 else {
            return nil // Not enough data for flags
        }
        
        let flags = data[0]
        let heartRateValueFormat = (flags & 0x01) // Bit 0
        
        var heartRate: Int?
        var offset = 1 // Start after flags byte
        
        if heartRateValueFormat == 0 { // Heart Rate Value Format is UInt8
            guard data.count >= offset + 1 else { return nil }
            heartRate = Int(data[offset])
            offset += 1
        } else { // Heart Rate Value Format is UInt16
            guard data.count >= offset + 2 else { return nil }
            // UInt16 values are typically Little Endian in Bluetooth GATT
            heartRate = Int(data[offset...offset+1].withUnsafeBytes { $0.load(as: UInt16.self).littleEndian })
            offset += 2
        }
        
        // Further parsing for Energy Expended or RR-Intervals can be added here if needed,
        // but for this task, we only need the heart rate value.
        
        return heartRate
    }
    
    public static func parseCSC(from data: Data) -> CSCData? {
        guard data.count >= 1 else { return nil }
        
        let flags = data[0]
        let wheelDataPresent = (flags & 0x01) != 0
        let crankDataPresent = (flags & 0x02) != 0
        
        var offset = 1
        
        var cumulativeWheelRevolutions: UInt32?
        var lastWheelEventTime: UInt16?
        if wheelDataPresent {
            guard data.count >= offset + 6 else { return nil }
            cumulativeWheelRevolutions = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
            offset += 4
            lastWheelEventTime = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            offset += 2
        }
        
        var cumulativeCrankRevolutions: UInt16?
        var lastCrankEventTime: UInt16?
        if crankDataPresent {
            guard data.count >= offset + 4 else { return nil }
            cumulativeCrankRevolutions = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            offset += 2
            lastCrankEventTime = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            offset += 2
        }
        
        return CSCData(
            cumulativeWheelRevolutions: cumulativeWheelRevolutions,
            lastWheelEventTime: lastWheelEventTime,
            cumulativeCrankRevolutions: cumulativeCrankRevolutions,
            lastCrankEventTime: lastCrankEventTime
        )
    }
    
    public static func parseCyclingPower(from data: Data) -> CyclingPowerData? {
        guard data.count >= 4 else { return nil }
        
        let flags = data.subdata(in: 0..<2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
        
        let pedalPowerBalancePresent = (flags & 0x0001) != 0
        let accumulatedTorquePresent = (flags & 0x0004) != 0
        let wheelDataPresent = (flags & 0x0010) != 0
        let crankDataPresent = (flags & 0x0020) != 0
        let accumulatedEnergyPresent = (flags & 0x0400) != 0
        
        var offset = 2
        
        guard data.count >= offset + 2 else { return nil }
        let instantaneousPower = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: Int16.self).littleEndian }
        offset += 2
        
        var pedalPowerBalance: UInt8?
        if pedalPowerBalancePresent {
            guard data.count >= offset + 1 else { return nil }
            pedalPowerBalance = data[offset]
            offset += 1
        }
        
        var accumulatedTorque: UInt16?
        if accumulatedTorquePresent {
            guard data.count >= offset + 2 else { return nil }
            accumulatedTorque = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            offset += 2
        }
        
        var cumulativeWheelRevolutions: UInt32?
        var lastWheelEventTime: UInt16?
        if wheelDataPresent {
            guard data.count >= offset + 6 else { return nil }
            cumulativeWheelRevolutions = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
            offset += 4
            lastWheelEventTime = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            offset += 2
        }
        
        var cumulativeCrankRevolutions: UInt16?
        var lastCrankEventTime: UInt16?
        if crankDataPresent {
            guard data.count >= offset + 4 else { return nil }
            cumulativeCrankRevolutions = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            offset += 2
            lastCrankEventTime = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            offset += 2
        }
        
        var accumulatedEnergy: UInt16?
        if accumulatedEnergyPresent {
            guard data.count >= offset + 2 else { return nil }
            accumulatedEnergy = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
            offset += 2
        }
        
        return CyclingPowerData(
            instantaneousPower: instantaneousPower,
            pedalPowerBalance: pedalPowerBalance,
            accumulatedTorque: accumulatedTorque,
            cumulativeWheelRevolutions: cumulativeWheelRevolutions,
            lastWheelEventTime: lastWheelEventTime,
            cumulativeCrankRevolutions: cumulativeCrankRevolutions,
            lastCrankEventTime: lastCrankEventTime,
            accumulatedEnergy: accumulatedEnergy
        )
    }
}
