import Foundation

public enum CreditStatus: String, Codable, Sendable {
    case ACTIVE, CLOSED, OVERDUE

    public var displayName: String {
        switch self {
        case .ACTIVE: "Активный"
        case .CLOSED: "Закрыт"
        case .OVERDUE: "Просрочен"
        }
    }
}
