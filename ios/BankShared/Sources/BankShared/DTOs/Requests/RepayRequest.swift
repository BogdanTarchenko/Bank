import Foundation

public struct RepayRequest: Codable, Sendable {
    public let amount: Decimal

    public init(amount: Decimal) {
        self.amount = amount
    }
}
