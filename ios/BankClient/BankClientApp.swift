import SwiftUI
import BankShared

@main
struct BankClientApp: App {
    @StateObject private var authManager = AuthManager(config: ClientConfiguration.auth)
    @State private var appState = AppState()
    @State private var httpClient = HTTPClient(baseURL: ClientConfiguration.bffBaseURL)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environment(appState)
                .preferredColorScheme(appState.preferredColorScheme)
                .task {
                    await httpClient.setTokenProvider { [weak authManager] in
                        await authManager?.getAccessToken()
                    }
                    await httpClient.setOnUnauthorized { [weak authManager] in
                        await authManager?.logout()
                    }
                }
        }
    }
}
