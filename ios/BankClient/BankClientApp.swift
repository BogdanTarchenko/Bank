import SwiftUI
import BankShared

@main
struct BankClientApp: App {
    @StateObject private var container = DependencyContainer()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(container.authManager)
                .environment(appState)
                .preferredColorScheme(appState.preferredColorScheme)
                .task {
                    await container.setup()
                    // Restore userId on app launch
                    if let userId = container.authManager.userId {
                        appState.currentUserId = userId
                    }
                }
                .onChange(of: container.authManager.userId) { _, newValue in
                    appState.currentUserId = newValue
                }
        }
    }
}
