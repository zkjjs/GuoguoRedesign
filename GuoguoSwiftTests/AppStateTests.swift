import XCTest
@testable import GuoguoSwift

final class AppStateTests: XCTestCase {
    func testRootDestinationSelection() {
        let state = AppState()
        XCTAssertEqual(state.selectedRoot, .home)

        state.selectedRoot = .search
        XCTAssertEqual(state.selectedRoot, .search)
    }
}
