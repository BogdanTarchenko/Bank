import SwiftUI
import BankShared

struct CreditRatingView: View {
    let rating: CreditRating

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Text(rating.grade)
                        .font(.system(size: 64, weight: .bold))
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

    private var gradeColor: Color {
        switch rating.grade {
        case "A", "A+": .green
        case "B", "B+": .blue
        case "C": .orange
        default: .red
        }
    }
}
