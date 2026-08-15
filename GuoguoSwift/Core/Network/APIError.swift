import Foundation

enum APIError: Error {
    case invalidResponse
    case httpStatus(Int, Data)
    case decoding(Error)
}
