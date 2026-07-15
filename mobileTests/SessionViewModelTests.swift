import XCTest
import Combine
import trainer.feature.presentation.trainer.training.session.viewModel
import trainer.feature.presentation.trainer.training.session.model
import trainer.feature.service

@testable import trainer

final class SessionViewModelTests: XCTestCase {
    var bluetoothManager: BluetoothManager!
    
    override func setUp() {
        super.setUp()
        bluetoothManager = BluetoothManager()
    }
    
    override func tearDown() {
        bluetoothManager = nil
        super.tearDown()
    }
    
    // As SessionViewModel logic depends on timer and orchestrator, 
    // real testing would require mocking those. For now, we test the logic we can.
    
    func testSessionCompletionTriggersModal() {
        let blocks = [MRCBlock(startTime: 0, endTime: 1, targetStartPower: 100, targetEndPower: 100)]
        let workout = MRCWorkout(name: "Test Workout", blocks: blocks)
        let viewModel = SessionViewModel(sensors: [], workout: workout, mrcFilePath: nil, bluetoothManager: bluetoothManager)
        
        // Mock session start
        viewModel.startSession()
        XCTAssertEqual(viewModel.state, .active)
        
        // Manually trigger completion
        viewModel.completeSession()
        
        XCTAssertEqual(viewModel.state, .completed)
        XCTAssertTrue(viewModel.showSummaryModal)
    }
}
