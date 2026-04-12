import SwiftUI
import BankShared

struct EmployeeMainTabView: View {
    @EnvironmentObject private var container: EmployeeDependencyContainer
    @Environment(EmployeeAppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            EmployeeUserListView()
                .tabItem {
                    Label("Пользователи", systemImage: "person.3")
                }
                .tag(0)

            EmployeeAllAccountsView()
                .tabItem {
                    Label("Счета", systemImage: "creditcard")
                }
                .tag(1)

            EmployeeTariffListView()
                .tabItem {
                    Label("Тарифы", systemImage: "percent")
                }
                .tag(2)

            EmployeeSettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
                .tag(3)

            if appState.showMonitoringTab {
                EmployeeMonitoringView()
                    .tabItem {
                        Label("Мониторинг", systemImage: "chart.bar.xaxis")
                    }
                    .tag(4)
            }
        }
        .onChange(of: selectedTab) { _, _ in
            guard let userId = appState.currentUserId else { return }
            Task {
                if let settings = try? await container.settingsUseCase.getSettings(userId: userId) {
                    appState.applySettings(settings)
                }
            }
        }
    }
}
