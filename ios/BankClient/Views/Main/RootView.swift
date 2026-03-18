import SwiftUI
import BankShared

struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView(authManager: authManager)
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}
