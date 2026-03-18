import Foundation

public struct CreateCreditRequest: Codable, Sendable {
    public let userId: Int64
    public let accountId: Int64
    public let tariffId: Int64
    public let amount: Decimal
    public let termDays: Int

    public init(userId: Int64, accountId: Int64, tariffId: Int64, amount: Decimal, termDays: Int) {
        self.userId = userId
        self.accountId = accountId
        self.tariffId = tariffId
        self.amount = amount
        self.termDays = termDays
    }
}
