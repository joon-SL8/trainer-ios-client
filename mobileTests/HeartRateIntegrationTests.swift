//
//  HeartRateIntegrationTests.swift
//  mobileTests
//
//  Created by mjlee-air on 2026/06/08.
//

import XCTest
import CoreBluetooth
import Combine
@testable import trainer // Import the main app module
@testable import libfitness // Import libfitness for HeartRatePacket and HeartRateContent

class HeartRateIntegrationTests: XCTestCase {

    var bluetoothManager: BluetoothManager!
    var sessionOrchestrator: SessionOrchestrator!
    var sessionViewModel: SessionViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        super.setUpWithError()
        bluetoothManager = BluetoothManager()
        sessionOrchestrator = SessionOrchestrator(bluetoothManager: bluetoothManager)
        sessionViewModel = SessionViewModel(bluetoothManager: bluetoothManager)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        bluetoothManager = nil
        sessionOrchestrator = nil
        sessionViewModel = nil
        cancellables = nil
        super.tearDownWithError()
    }
    
    func testHeartRateDataFlowEndToEnd() throws {
        // Given: A simulated peripheral sending heart rate data
        let testPeripheralIdentifier = UUID()
        let expectedHeartRate = 75
        let heartRateData = Data([0x06, UInt8(expectedHeartRate)]) // Flags (UInt8 format + sensor contact detected), Heart Rate Value

        let expectation = XCTestExpectation(description: "Heart rate data should flow through to SessionViewModel")

        sessionViewModel.$heartRate
            .dropFirst() // Drop initial nil value
            .sink { hr in
                XCTAssertNotNil(hr, "Heart rate should not be nil")
                XCTAssertEqual(hr, Double(expectedHeartRate), "Received heart rate should match expected value")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate BluetoothManager discovering and publishing data
        bluetoothManager.dataPublisher.send((testPeripheralIdentifier, heartRateData))

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testBluetoothManagerPublishesHeartRateData() throws {
        // Given: A mock peripheral and characteristic with known heart rate data
        let mockPeripheral = MockPeripheral()
        let heartRateCharacteristicUUID = CBUUID(string: "2A37")
        let testHeartRate = 60
        let testCharacteristicData = Data([0x06, UInt8(testHeartRate)]) // UInt8 format, Heart Rate Value

        let expectation = XCTestExpectation(description: "BluetoothManager should publish the parsed heart rate data")

        bluetoothManager.dataPublisher
            .sink { (peripheralId, data) in
                XCTAssertEqual(peripheralId, mockPeripheral.identifier, "Peripheral ID should match")
                XCTAssertEqual(data, Data([UInt8(testHeartRate)]), "Published data should be the parsed heart rate value")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate BluetoothManager's delegate method being called
        let mockCharacteristic = CBMutableCharacteristic(type: heartRateCharacteristicUUID, properties: [.notify, .read], value: testCharacteristicData, permissions: [.readable])
        
        bluetoothManager.peripheral(mockPeripheral, didUpdateValueFor: mockCharacteristic, error: nil)

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSessionOrchestratorProcessesHeartRateData() throws {
        // Given: Simulated heart rate data from BluetoothManager
        let testPeripheralIdentifier = UUID()
        let expectedHeartRate = 80
        let heartRateData = Data([UInt8(expectedHeartRate)]) // Already parsed heart rate value

        let expectation = XCTestExpectation(description: "SessionOrchestrator should process heart rate data and publish HeartRateContent")

        sessionOrchestrator.$currentHeartRateContent
            .compactMap { $0 } // Only interested in non-nil values
            .sink { content in
                XCTAssertEqual(content.content.hrData, Int32(expectedHeartRate), "HeartRateContent should contain the correct heart rate")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate BluetoothManager publishing data to the orchestrator
        bluetoothManager.dataPublisher.send((testPeripheralIdentifier, CBUUID(string: "2A37"), heartRateData))

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSessionOrchestratorProcessesCSCData() throws {
        // Given: Simulated CSC data from BluetoothManager
        let testPeripheralIdentifier = UUID()
        // Flags (wheel data present, crank data present), revs, time...
        let cscData = Data([0x03, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00])

        let expectation = XCTestExpectation(description: "SessionOrchestrator should process CSC data and publish cscData")

        sessionOrchestrator.$cscData
            .compactMap { $0 } // Only interested in non-nil values
            .sink { data in
                XCTAssertNotNil(data, "CSCData should not be nil")
                XCTAssertEqual(data.cumulativeWheelRevolutions, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate BluetoothManager publishing data to the orchestrator
        bluetoothManager.dataPublisher.send((testPeripheralIdentifier, CBUUID(string: "2A5B"), cscData))

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSessionOrchestratorProcessesCyclingPowerData() throws {
        // Given: Simulated CP data from BluetoothManager
        let testPeripheralIdentifier = UUID()
        // Flags: instantaneous power present only (0x0000?), power=100W (0x6400)
        let cpData = Data([0x00, 0x00, 0x64, 0x00]) 

        let expectation = XCTestExpectation(description: "SessionOrchestrator should process Cycling Power data and publish cyclingPowerData")

        sessionOrchestrator.$cyclingPowerData
            .compactMap { $0 } // Only interested in non-nil values
            .sink { data in
                XCTAssertNotNil(data, "CyclingPowerData should not be nil")
                XCTAssertEqual(data.instantaneousPower, 100)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate BluetoothManager publishing data to the orchestrator
        bluetoothManager.dataPublisher.send((testPeripheralIdentifier, CBUUID(string: "2A63"), cpData))

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSessionMetricHeaderHeartRateDisplay() throws {
        let expectedHeartRate = 90
        
        // Test with heart rate data
        let heartRatePacket = HeartRatePacket(hrData: Int32(expectedHeartRate))
        let heartRateContent = HeartRateContent(content: heartRatePacket)
        sessionViewModel.currentHeartRateContent = heartRateContent
        
        XCTAssertEqual(sessionViewModel.heartRate, Double(expectedHeartRate), "SessionViewModel should reflect the heart rate from content")
        // Since SessionMetricHeader directly observes sessionViewModel, if viewModel.heartRate is correct,
        // and currentHeartRateContent is correctly set, the UI display should follow.
        // Direct UI element inspection is not possible in XCTest unit tests.
        
        // Test with no heart rate data (fallback)
        sessionViewModel.currentHeartRateContent = nil
        XCTAssertNil(sessionViewModel.heartRate, "SessionViewModel heart rate should be nil when content is nil")
    }
}

// Mocking CBPeripheral for testing purposes
// (This is a simplified mock and might need to be expanded for more complex scenarios)
class MockPeripheral: CBPeripheral {
    override var identifier: UUID {
        return UUID() // Return a unique ID for each mock
    }
    
    override var name: String? {
        return "Mock Heart Rate Sensor"
    }
}
