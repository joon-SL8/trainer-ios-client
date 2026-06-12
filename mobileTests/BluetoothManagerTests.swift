import XCTest
import CoreBluetooth
@testable import mobile

final class BluetoothManagerTests: XCTestCase {
    var bluetoothManager: BluetoothManager!

    override func setUp() {
        super.setUp()
        bluetoothManager = BluetoothManager()
    }

    override func tearDown() {
        bluetoothManager = nil
        super.tearDown()
    }

    func testInitialStateIsUnknown() {
        XCTAssertEqual(bluetoothManager.state, .unknown)
        XCTAssertFalse(bluetoothManager.permissionDenied)
    }

    // Since we cannot easily mock CBCentralManager without protocols,
    // we would ideally refactor BluetoothManager to use a CentralManagerProtocol.
    // For now, we verify the initial state and the presence of core methods.

    func testRequestPermissionExists() {
        // This just ensures the method is callable
        bluetoothManager.requestPermission()
    }
    
    func testStartScanningConditions() {
        // Initially state is unknown, so scanning should not start (guard clause)
        bluetoothManager.startScanning()
        // No easy way to verify CBCentralManager scan call without mocking, 
        // but this verifies the method doesn't crash.
    }
}
