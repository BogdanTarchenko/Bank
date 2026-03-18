import SwiftUI
import BankShared

struct PaymentRow: View {
    let payment: Payment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.amount.formattedPlain())
                    .font(.subheadline.bold())
                Text("Срок: \(payment.dueDate.toShortDate())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let paidAt = payment.paidAt {
                    Text("Оплачен: \(paidAt.toDisplayDate())")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            StatusBadge(paymentStatus: payment.status)
        }
    }
}
