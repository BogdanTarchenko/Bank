import Foundation

public extension Decimal {
    func formatted(currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        let number = formatter.string(from: self as NSDecimalNumber) ?? "0.00"
        return "\(number) \(currency.symbol)"
    }

    func formattedPlain() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        return formatter.string(from: self as NSDecimalNumber) ?? "0.00"
    }
}
