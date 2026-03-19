import SwiftUI
import BankShared

@main
struct BankEmployeeApp: App {
    @StateObject private var container = EmployeeDependencyContainer()
    @State private var appState = EmployeeAppState()
    @Environment(\.scenePhase) private var scenePhase

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
                .task(id: appState.currentUserId) {
                    guard let userId = appState.currentUserId else { return }
                    await loadSettings(userId: userId)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active, let userId = appState.currentUserId {
                        Task { await loadSettings(userId: userId) }
                    }
                }
        }
    }

    private func loadSettings(userId: Int64) async {
        do {
            let settings = try await container.settingsUseCase.getSettings(userId: userId)
            appState.applySettings(settings)
        } catch {
            // Используем локально сохранённые настройки (UserDefaults)
        }
    }
}
