import SwiftUI
import BankShared

struct CreditRatingView: View {
    let rating: CreditRating

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Text(gradeDisplayName)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(gradeColor)
                    Text("\(rating.score) баллов")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Section("Статистика") {
                LabeledContent("Всего кредитов", value: "\(rating.totalCredits)")
                LabeledContent("Активных", value: "\(rating.activeCredits)")
                LabeledContent("Всего платежей", value: "\(rating.totalPayments)")
                LabeledContent("Просроченных", value: "\(rating.overduePayments)")
            }
        }
        .navigationTitle("Кредитный рейтинг")
    }

    private var gradeDisplayName: String {
        switch rating.grade.uppercased() {
        case "EXCELLENT": "Отличный"
        case "GOOD": "Хороший"
        case "FAIR": "Средний"
        case "POOR": "Низкий"
        case "BAD": "Плохой"
        default: rating.grade
        }
    }

    private var gradeColor: Color {
        switch rating.grade.uppercased() {
        case "EXCELLENT": .green
        case "GOOD": .blue
        case "FAIR": .orange
        case "POOR": .red
        case "BAD": .red
        default: .secondary
        }
    }
}
