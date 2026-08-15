import XCTest
@testable import GuoguoSwift

final class AuthSessionTests: XCTestCase {
    func testInjectsOnlyConfiguredHeaders() {
        var session = AuthSession()
        session.xToken = "x-value"

        XCTAssertEqual(session.headers["X-Token"], "x-value")
        XCTAssertNil(session.headers["PLAY-TOKEN"])
        XCTAssertNil(session.headers["authorization"])
        XCTAssertNil(session.headers["cookie"])
    }

    func testSupportsPlaybackAndAuthorizationHeaders() {
        var session = AuthSession()
        session.authorization = "Bearer token"
        session.cookie = "session=abc"
        session.playToken = "play-value"

        XCTAssertEqual(session.headers["authorization"], "Bearer token")
        XCTAssertEqual(session.headers["cookie"], "session=abc")
        XCTAssertEqual(session.headers["PLAY-TOKEN"], "play-value")
    }
}
