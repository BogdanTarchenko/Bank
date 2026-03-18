import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AccountListView()
                .tabItem {
                    Label("Счета", systemImage: "creditcard")
                }

            CreditListView()
                .tabItem {
                    Label("Кредиты", systemImage: "banknote")
                }

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
        }
    }
}
