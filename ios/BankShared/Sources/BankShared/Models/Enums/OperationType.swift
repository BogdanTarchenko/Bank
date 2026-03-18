import Foundation

public enum OperationType: String, Codable, Sendable {
    case DEPOSIT, WITHDRAWAL, TRANSFER_IN, TRANSFER_OUT

    public var displayName: String {
        switch self {
        case .DEPOSIT: "Пополнение"
        case .WITHDRAWAL: "Снятие"
        case .TRANSFER_IN: "Входящий перевод"
        case .TRANSFER_OUT: "Исходящий перевод"
        }
    }

    public var isIncoming: Bool {
        self == .DEPOSIT || self == .TRANSFER_IN
    }
}
