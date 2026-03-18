import Foundation

public struct Credit: Codable, Identifiable, Sendable {
    public let id: Int64
    public let userId: Int64
    public let accountId: Int64
    public let tariffId: Int64
    public let tariffName: String
    public let principal: Decimal
    public let remaining: Decimal
    public let interestRate: Decimal
    public let termDays: Int
    public let dailyPayment: Decimal
    public let status: CreditStatus
    public let createdAt: String
    public let closedAt: String?
}
