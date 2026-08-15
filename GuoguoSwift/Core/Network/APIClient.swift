import Foundation

actor APIClient {
    static let baseURL = URL(string: "https://vod.api.zshtys888.com")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send<T: Decodable>(_ request: APIRequest, as type: T.Type) async throws -> T {
        let urlRequest = try request.makeURLRequest(baseURL: Self.baseURL)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIError.httpStatus(httpResponse.statusCode, data)
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
