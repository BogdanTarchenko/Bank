import Foundation

public struct CreateAccountRequest: Codable, Sendable {
    public let userId: Int64
    public let currency: Currency

    public init(userId: Int64, currency: Currency) {
        self.userId = userId
        self.currency = currency
    }
}
