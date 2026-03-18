import Foundation

public struct TransferRequest: Codable, Sendable {
    public let fromAccountId: Int64
    public let toAccountId: Int64
    public let amount: Decimal

    public init(fromAccountId: Int64, toAccountId: Int64, amount: Decimal) {
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
        self.amount = amount
    }
}
