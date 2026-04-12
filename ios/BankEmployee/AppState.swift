import SwiftUI
import BankShared

@MainActor
@Observable
final class EmployeeAppState {
    var currentUserId: Int64?

    var theme: Theme = .LIGHT {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "employee_app_theme")
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .LIGHT: .light
        case .DARK: .dark
        }
    }

    var showMonitoringTab: Bool = UserDefaults.standard.bool(forKey: "employee_show_monitoring") {
        didSet {
            UserDefaults.standard.set(showMonitoringTab, forKey: "employee_show_monitoring")
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "employee_app_theme"),
           let savedTheme = Theme(rawValue: saved) {
            self.theme = savedTheme
        }
    }

    func applySettings(_ settings: UserSettings) {
        theme = settings.theme
    }
}
