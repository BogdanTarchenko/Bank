import SwiftUI
import BankShared

@main
struct BankEmployeeApp: App {
    @StateObject private var container = EmployeeDependencyContainer()
    @State private var appState = EmployeeAppState()

    var body: some Scene {
        WindowGroup {
            EmployeeRootView()
                .environmentObject(container)
                .environmentObject(container.authManager)
                .environment(appState)
                .preferredColorScheme(appState.preferredColorScheme)
                .task {
                    await container.setup()
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
