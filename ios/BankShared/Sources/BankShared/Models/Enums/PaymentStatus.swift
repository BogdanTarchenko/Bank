import Foundation

public enum PaymentStatus: String, Codable, Sendable {
    case PENDING, PAID, OVERDUE

    public var displayName: String {
        switch self {
        case .PENDING: "Ожидает"
        case .PAID: "Оплачен"
        case .OVERDUE: "Просрочен"
        }
    }
}
