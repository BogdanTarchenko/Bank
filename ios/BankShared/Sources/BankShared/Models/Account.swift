import Foundation

public struct Account: Codable, Identifiable, Sendable {
    public let id: Int64
    public let userId: Int64
    public let currency: Currency
    public let balance: Decimal
    public let accountType: AccountType
    public let isClosed: Bool
    public let createdAt: String
}
