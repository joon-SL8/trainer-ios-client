import XCTest
@testable import mobile
@testable import trainer

final class BluetoothDataParserTests: XCTestCase {
    
    func testParseCSC() {
        // Flags: Bit 0 (Wheel) + Bit 1 (Crank) = 0x03
        // CumulativeWheel: 100 (0x00000064)
        // LastWheelTime: 1024 (0x0400)
        // CumulativeCrank: 50 (0x0032)
        // LastCrankTime: 512 (0x0200)
        var data = Data([0x03]) // Flags
        data.append(contentsOf: [0x64, 0x00, 0x00, 0x00]) // CumWheel
        data.append(contentsOf: [0x00, 0x04]) // LastWheelTime
        data.append(contentsOf: [0x32, 0x00]) // CumCrank
        data.append(contentsOf: [0x00, 0x02]) // LastCrankTime
        
        let cscData = BluetoothDataParser.parseCSC(from: data)
        XCTAssertNotNil(cscData)
        XCTAssertEqual(cscData?.cumulativeWheelRevolutions, 100)
        XCTAssertEqual(cscData?.lastWheelEventTime, 1024)
        XCTAssertEqual(cscData?.cumulativeCrankRevolutions, 50)
        XCTAssertEqual(cscData?.lastCrankEventTime, 512)
    }
    
    func testParseCyclingPower() {
        // Flags: 0x0000. Data: [0x00, 0x00] (Flags), [0x64, 0x00] (Power = 100)
        var data = Data([0x00, 0x00]) // Flags
        data.append(contentsOf: [0x64, 0x00]) // Power = 100
        
        let cpData = BluetoothDataParser.parseCyclingPower(from: data)
        XCTAssertNotNil(cpData)
        XCTAssertEqual(cpData?.instantaneousPower, 100)
        XCTAssertNil(cpData?.pedalPowerBalance)
    }
}
