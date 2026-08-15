import XCTest
@testable import GuoguoSwift

final class APIEndpointTests: XCTestCase {
    func testVideoSearchPath() {
        XCTAssertEqual(APIEndpoint.videoSearch.path, "/app/video/search")
    }

    func testCoreViewingPaths() {
        XCTAssertEqual(APIEndpoint.appConfig.path, "/app/config")
        XCTAssertEqual(APIEndpoint.banners.path, "/app/banners/")
        XCTAssertEqual(APIEndpoint.channels.path, "/app/channel/")
        XCTAssertEqual(APIEndpoint.videoList.path, "/app/video/list")
        XCTAssertEqual(APIEndpoint.videoDetail.path, "/app/video/detail")
        XCTAssertEqual(APIEndpoint.videoPlay.path, "/app/video/play")
        XCTAssertEqual(APIEndpoint.playbackToken.path, "/app/playaddr/get/token")
        XCTAssertEqual(APIEndpoint.playbackAddressV3.path, "/app/playaddr/v3/get")
    }
}
