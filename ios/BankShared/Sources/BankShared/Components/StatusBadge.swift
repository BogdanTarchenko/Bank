import SwiftUI

public struct StatusBadge: View {
    let text: String
    let color: Color

    public init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

public extension StatusBadge {
    init(creditStatus: CreditStatus) {
        switch creditStatus {
        case .ACTIVE: self.init(creditStatus.displayName, color: .green)
        case .CLOSED: self.init(creditStatus.displayName, color: .gray)
        case .OVERDUE: self.init(creditStatus.displayName, color: .red)
        }
    }

    init(paymentStatus: PaymentStatus) {
        switch paymentStatus {
        case .PENDING: self.init(paymentStatus.displayName, color: .orange)
        case .PAID: self.init(paymentStatus.displayName, color: .green)
        case .OVERDUE: self.init(paymentStatus.displayName, color: .red)
        }
    }
}
