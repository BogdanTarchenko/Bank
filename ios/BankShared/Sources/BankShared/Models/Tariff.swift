import Foundation

public struct Tariff: Codable, Identifiable, Sendable {
    public let id: Int64
    public let name: String
    public let interestRate: Decimal
    public let minAmount: Decimal?
    public let maxAmount: Decimal?
    public let minTermDays: Int?
    public let maxTermDays: Int?
    public let active: Bool
    public let createdAt: String
}
