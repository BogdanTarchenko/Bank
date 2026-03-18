import Foundation

public struct RegisterRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let firstName: String
    public let lastName: String
    public let phone: String?
    public let roles: Set<String>?

    public init(email: String, password: String, firstName: String, lastName: String, phone: String? = nil, roles: Set<String>? = nil) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.roles = roles
    }
}
