import SwiftUI
import BankShared

@main
struct BankEmployeeApp: App {
    @StateObject private var authManager = AuthManager(config: EmployeeConfiguration.auth)
    @State private var appState = EmployeeAppState()
    @State private var httpClient = HTTPClient(baseURL: EmployeeConfiguration.bffBaseURL)

    var body: some Scene {
        WindowGroup {
            EmployeeRootView()
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
