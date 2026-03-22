import Foundation

public enum UserRole: String, Codable, CaseIterable, Sendable {
    case CLIENT, EMPLOYEE

    public var displayName: String {
        switch self {
        case .CLIENT: "Клиент"
        case .EMPLOYEE: "Сотрудник"
        }
    }
}
