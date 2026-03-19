import SwiftUI
import BankShared

@MainActor
@Observable
final class AppState {
    var currentUserId: Int64?
    var hiddenAccounts: Set<Int64> = []
    var showHiddenAccounts = false

    var theme: Theme = .LIGHT {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .LIGHT: .light
        case .DARK: .dark
        }
    }

    init() {
        // Восстановить тему из локального хранилища (до загрузки с сервера)
        if let saved = UserDefaults.standard.string(forKey: "app_theme"),
           let savedTheme = Theme(rawValue: saved) {
            self.theme = savedTheme
        }
        // Восстановить скрытые счета
        if let savedHidden = UserDefaults.standard.array(forKey: "hidden_accounts") as? [Int64] {
            self.hiddenAccounts = Set(savedHidden)
        }
    }

    /// Применить настройки с сервера и синхронизировать с локальным хранилищем
    func applySettings(_ settings: UserSettings) {
        theme = settings.theme
        hiddenAccounts = Set(settings.hiddenAccounts)
        UserDefaults.standard.set(Array(hiddenAccounts), forKey: "hidden_accounts")
    }

    func toggleHidden(accountId: Int64) {
        if hiddenAccounts.contains(accountId) {
            hiddenAccounts.remove(accountId)
        } else {
            hiddenAccounts.insert(accountId)
        }
        UserDefaults.standard.set(Array(hiddenAccounts), forKey: "hidden_accounts")
    }

    func isHidden(accountId: Int64) -> Bool {
        hiddenAccounts.contains(accountId)
    }
}
