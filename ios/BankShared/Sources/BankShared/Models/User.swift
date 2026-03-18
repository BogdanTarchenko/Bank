import Foundation

public struct User: Codable, Identifiable, Sendable {
    public let id: Int64
    public let email: String
    public let firstName: String
    public let lastName: String
    public let phone: String?
    public let blocked: Bool
    public let roles: Set<UserRole>
    public let createdAt: String
    public let updatedAt: String

    public var fullName: String { "\(firstName) \(lastName)" }
}
