import Foundation

public enum Validator {
    public static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    public static func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }

    public static func isValidAmount(_ amount: String) -> Bool {
        guard let value = Decimal(string: amount) else { return false }
        return value > 0
    }
}
