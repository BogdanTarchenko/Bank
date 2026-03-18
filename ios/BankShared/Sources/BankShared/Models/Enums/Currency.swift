import Foundation

public enum Currency: String, Codable, CaseIterable, Sendable {
    case RUB, USD, EUR

    public var symbol: String {
        switch self {
        case .RUB: "₽"
        case .USD: "$"
        case .EUR: "€"
        }
    }
}
