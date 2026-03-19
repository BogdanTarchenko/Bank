import SwiftUI
import BankShared

struct EmployeeRootView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                EmployeeMainTabView()
            } else {
                EmployeeLoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
        .sheet(isPresented: $authManager.showLoginWebView) {
            if let authURL = authManager.buildAuthURL() {
                NavigationStack {
                    OAuthWebView(
                        url: authURL,
                        redirectScheme: URL(string: authManager.authConfig.redirectUri)!.scheme!,
                        onCallback: { url in
                            Task { await authManager.handleCallback(url: url) }
                        },
                        onCancel: {
                            authManager.cancelLogin()
                        }
                    )
                    .navigationTitle("Вход")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") {
                                authManager.cancelLogin()
                            }
                        }
                    }
                }
            }
        }
    }
}
