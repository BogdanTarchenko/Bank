import Foundation

public struct CreditRating: Codable, Sendable {
    public let userId: Int64
    public let score: Int
    public let grade: String
    public let totalCredits: Int
    public let activeCredits: Int
    public let overduePayments: Int
    public let totalPayments: Int
}
