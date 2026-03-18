import SwiftUI

public struct AmountTextField: View {
    let title: String
    @Binding var text: String
    let currency: Currency?

    public init(_ title: String = "Сумма", text: Binding<String>, currency: Currency? = nil) {
        self.title = title
        self._text = text
        self.currency = currency
    }

    public var body: some View {
        HStack {
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
            if let currency {
                Text(currency.symbol)
                    .foregroundStyle(.secondary)
                    .font(.headline)
            }
        }
    }
}
