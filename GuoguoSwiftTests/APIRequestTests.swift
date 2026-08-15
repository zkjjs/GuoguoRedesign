import XCTest
@testable import GuoguoSwift

final class APIRequestTests: XCTestCase {
    func testBuildsGETRequestWithQueryAndHeaders() throws {
        let request = APIRequest(
            method: .get,
            endpoint: .videoSearch,
            queryItems: [URLQueryItem(name: "keyword", value: "斗罗")],
            headers: ["X-Token": "abc"]
        )

        let urlRequest = try request.makeURLRequest(
            baseURL: URL(string: "https://vod.api.zshtys888.com")!
        )

        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "X-Token"), "abc")
        XCTAssertEqual(urlRequest.url?.host, "vod.api.zshtys888.com")
        XCTAssertEqual(urlRequest.url?.path, "/app/video/search")
        XCTAssertEqual(URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.name, "keyword")
        XCTAssertEqual(URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "斗罗")
    }

    func testBuildsJSONPOSTRequest() throws {
        let body = Data(#"{"id":"123"}"#.utf8)
        let request = APIRequest(
            method: .post,
            endpoint: .videoDetail,
            headers: ["authorization": "Bearer value"],
            body: body
        )

        let urlRequest = try request.makeURLRequest(
            baseURL: URL(string: "https://vod.api.zshtys888.com")!
        )

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.httpBody, body)
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "authorization"), "Bearer value")
    }
}
