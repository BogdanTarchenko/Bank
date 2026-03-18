import Foundation

public struct MoneyOperationRequest: Codable, Sendable {
    public let amount: Decimal

    public init(amount: Decimal) {
        self.amount = amount
    }
}
