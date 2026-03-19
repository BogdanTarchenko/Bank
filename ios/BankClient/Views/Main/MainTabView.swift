import SwiftUI
import BankShared

struct MainTabView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AccountListView()
                .tabItem {
                    Label("Счета", systemImage: "creditcard")
                }
                .tag(0)

            CreditListView()
                .tabItem {
                    Label("Кредиты", systemImage: "banknote")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { _, _ in
            // При переключении табов — синхронизировать настройки с сервером
            guard let userId = appState.currentUserId else { return }
            Task {
                if let settings = try? await container.settingsUseCase.getSettings(userId: userId) {
                    appState.applySettings(settings)
                }
            }
        }
    }
}
