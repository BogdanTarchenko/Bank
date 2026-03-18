import Foundation

public extension String {
    func toDisplayDate() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        if let date = formatter.date(from: self) {
            let display = DateFormatter()
            display.dateFormat = "dd.MM.yyyy HH:mm"
            display.locale = Locale(identifier: "ru_RU")
            return display.string(from: date)
        }
        // Try without timezone (LocalDateTime format)
        let local = DateFormatter()
        local.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = local.date(from: String(self.prefix(19))) {
            let display = DateFormatter()
            display.dateFormat = "dd.MM.yyyy HH:mm"
            display.locale = Locale(identifier: "ru_RU")
            return display.string(from: date)
        }
        return self
    }

    func toShortDate() -> String {
        let local = DateFormatter()
        local.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = local.date(from: String(self.prefix(19))) {
            let display = DateFormatter()
            display.dateFormat = "dd.MM.yyyy"
            display.locale = Locale(identifier: "ru_RU")
            return display.string(from: date)
        }
        return self
    }
}
