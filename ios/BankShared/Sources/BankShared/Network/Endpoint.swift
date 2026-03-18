import Foundation

public protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var body: (any Encodable & Sendable)? { get }
    var queryItems: [URLQueryItem]? { get }
}

public extension Endpoint {
    var body: (any Encodable & Sendable)? { nil }
    var queryItems: [URLQueryItem]? { nil }
}
