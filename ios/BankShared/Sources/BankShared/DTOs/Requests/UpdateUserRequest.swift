import Foundation

public struct UpdateUserRequest: Codable, Sendable {
    public let email: String?
    public let firstName: String?
    public let lastName: String?
    public let phone: String?

    public init(email: String? = nil, firstName: String? = nil, lastName: String? = nil, phone: String? = nil) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
    }
}
