import Foundation

public struct CreateTariffRequest: Codable, Sendable {
    public let name: String
    public let interestRate: Decimal
    public let minAmount: Decimal?
    public let maxAmount: Decimal?
    public let minTermDays: Int?
    public let maxTermDays: Int?

    public init(name: String, interestRate: Decimal, minAmount: Decimal? = nil, maxAmount: Decimal? = nil, minTermDays: Int? = nil, maxTermDays: Int? = nil) {
        self.name = name
        self.interestRate = interestRate
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.minTermDays = minTermDays
        self.maxTermDays = maxTermDays
    }
}
