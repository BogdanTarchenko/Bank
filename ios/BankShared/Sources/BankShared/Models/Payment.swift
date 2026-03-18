import Foundation

public struct Payment: Codable, Identifiable, Sendable {
    public let id: Int64
    public let creditId: Int64
    public let amount: Decimal
    public let status: PaymentStatus
    public let dueDate: String
    public let paidAt: String?
}
