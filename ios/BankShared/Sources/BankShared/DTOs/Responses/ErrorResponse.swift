import Foundation

public struct ErrorResponse: Codable, Sendable {
    public let status: Int
    public let error: String
    public let message: String
    public let timestamp: String
}
