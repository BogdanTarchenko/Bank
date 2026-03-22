import SwiftUI
import BankShared

@main
struct BankClientApp: App {
    @StateObject private var container = DependencyContainer()
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(container.authManager)
                .environment(appState)
                .preferredColorScheme(appState.preferredColorScheme)
                .task {
                    print("[APP] .task: starting setup...")
                    await container.setup()
                    print("[APP] .task: setup done, userId=\(container.authManager.userId as Any), isAuth=\(container.authManager.isAuthenticated)")
                    if let userId = container.authManager.userId {
                        appState.currentUserId = userId
                        print("[APP] .task: set currentUserId=\(userId)")
                    }
                    if container.authManager.isAuthenticated && container.authManager.userId == nil {
                        print("[APP] .task: userId still nil, retrying...")
                        await container.authManager.resolveUserIdIfNeeded()
                        if let userId = container.authManager.userId {
                            appState.currentUserId = userId
                            print("[APP] .task: resolved currentUserId=\(userId)")
                        } else {
                            print("[APP] .task: userId still nil after retry")
                        }
                    }
                }
                .onReceive(container.authManager.$isAuthenticated) { isAuth in
                    print("[APP] onReceive isAuthenticated → \(isAuth)")
                    if isAuth && container.authManager.userId == nil {
                        Task {
                            print("[APP] auth=true but userId=nil, resolving...")
                            await container.authManager.resolveUserIdIfNeeded()
                            if let userId = container.authManager.userId {
                                appState.currentUserId = userId
                                print("[APP] resolved userId=\(userId)")
                            } else {
                                print("[APP] userId still nil after resolve")
                            }
                        }
                    }
                    if !isAuth {
                        appState.currentUserId = nil
                        print("[APP] logged out, cleared currentUserId")
                    }
                }
                .onReceive(container.authManager.$userId) { newValue in
                    print("[APP] onReceive userId → \(newValue as Any)")
                    appState.currentUserId = newValue
                }
                .task(id: appState.currentUserId) {
                    guard let userId = appState.currentUserId else { return }
                    print("[APP] task(id:) loading settings for userId=\(userId)")
                    await loadSettings(userId: userId)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            if container.authManager.isAuthenticated && container.authManager.userId == nil {
                                await container.authManager.resolveUserIdIfNeeded()
                                if let userId = container.authManager.userId {
                                    appState.currentUserId = userId
                                }
                            }
                            if let userId = appState.currentUserId {
                                await loadSettings(userId: userId)
                            }
                        }
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
