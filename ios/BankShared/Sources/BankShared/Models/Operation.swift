import Foundation

public struct Operation: Codable, Identifiable, Sendable {
    public let id: Int64
    public let accountId: Int64
    public let type: OperationType
    public let amount: Decimal
    public let currency: Currency
    public let relatedAccountId: Int64?
    public let exchangeRate: Decimal?
    public let description: String?
    public let createdAt: String
}
