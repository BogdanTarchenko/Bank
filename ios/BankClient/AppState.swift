import SwiftUI
import BankShared

@MainActor
@Observable
final class AppState {
    var currentUserId: Int64?
    var theme: Theme = .LIGHT

    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .LIGHT: .light
        case .DARK: .dark
        }
    }
}
