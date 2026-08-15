import XCTest
@testable import GuoguoSwift

final class APIClientTests: XCTestCase {
    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    func testDecodesSuccessfulJSONResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = APIClient(session: session)

        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/app/config")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"name":"Guoguo"}"#.utf8))
        }

        let result = try await client.send(
            APIRequest(method: .get, endpoint: .appConfig),
            as: ClientFixture.self
        )

        XCTAssertEqual(result.name, "Guoguo")
    }

    func testThrowsHTTPStatusForNonSuccessResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let client = APIClient(session: URLSession(configuration: configuration))

        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("unauthorized".utf8))
        }

        do {
            _ = try await client.send(
                APIRequest(method: .get, endpoint: .appConfig),
                as: ClientFixture.self
            )
            XCTFail("Expected HTTP status error")
        } catch let error as APIError {
            guard case .httpStatus(let statusCode, let data) = error else {
                return XCTFail("Unexpected APIError: \(error)")
            }
            XCTAssertEqual(statusCode, 401)
            XCTAssertEqual(String(data: data, encoding: .utf8), "unauthorized")
        }
    }
}

private struct ClientFixture: Decodable {
    let name: String
}

private final class StubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
