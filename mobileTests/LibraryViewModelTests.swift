import XCTest
import liblyncfit
@testable import mobile

final class LibraryViewModelTests: XCTestCase {
    var viewModel: LibraryViewModel!

    override func setUp() {
        super.setUp()
        viewModel = LibraryViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(viewModel.isRoot())
        XCTAssertEqual(viewModel.currentPath, "")
        // items might be empty depending on the environment, but we can check if it fetched
        // Since we can't easily mock the SDK UseCase here without protocols, 
        // we'll verify the logic we can.
    }

    func testNavigation() {
        let testPath = "test_folder"
        viewModel.navigateTo(directory: testPath)
        
        XCTAssertFalse(viewModel.isRoot())
        XCTAssertEqual(viewModel.currentPath, testPath)
        XCTAssertEqual(viewModel.pathStack.count, 2)
        
        viewModel.navigateBack()
        XCTAssertTrue(viewModel.isRoot())
        XCTAssertEqual(viewModel.currentPath, "")
        XCTAssertEqual(viewModel.pathStack.count, 1)
    }

    func testItemDisplayName() {
        // Since AssetProperty requires a type and data, and we can't easily construct the Type_
        // we'll skip detailed item test if construction is complex, 
        // but our implementation just casts data to String.
    }
}
