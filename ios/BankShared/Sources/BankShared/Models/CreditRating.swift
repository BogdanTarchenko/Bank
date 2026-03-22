import SwiftUI

public struct CreditRating: Codable, Sendable {
    public let userId: Int64
    public let score: Int
    public let grade: String
    public let totalCredits: Int
    public let activeCredits: Int
    public let overduePayments: Int
    public let totalPayments: Int
}

public enum CreditGrade {
    public static func displayName(_ grade: String) -> String {
        switch grade.uppercased() {
        case "EXCELLENT": return "Отличный"
        case "GOOD": return "Хороший"
        case "FAIR": return "Средний"
        case "POOR": return "Низкий"
        case "BAD": return "Плохой"
        default: return grade
        }
    }

    public static func color(_ grade: String) -> Color {
        switch grade.uppercased() {
        case "EXCELLENT": return .green
        case "GOOD": return .blue
        case "FAIR": return .orange
        case "POOR", "BAD": return .red
        default: return .gray
        }
    }
}
