import Foundation

public struct CreateAccountRequest: Codable, Sendable {
    public let currency: Currency

    public init(currency: Currency) {
        self.currency = currency
    }
}
