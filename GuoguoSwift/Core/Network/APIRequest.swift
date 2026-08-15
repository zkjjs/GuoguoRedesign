import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct APIRequest {
    let method: HTTPMethod
    let endpoint: APIEndpoint
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Data?

    init(
        method: HTTPMethod,
        endpoint: APIEndpoint,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.endpoint = endpoint
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }

    func makeURLRequest(baseURL: URL) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIRequestError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIRequestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        if body != nil, request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}

enum APIRequestError: Error {
    case invalidURL
}
