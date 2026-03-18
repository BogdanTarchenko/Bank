import SwiftUI

public struct CurrencyBadge: View {
    let currency: Currency

    public init(_ currency: Currency) {
        self.currency = currency
    }

    public var body: some View {
        Text(currency.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var color: Color {
        switch currency {
        case .RUB: .blue
        case .USD: .green
        case .EUR: .purple
        }
    }
}
