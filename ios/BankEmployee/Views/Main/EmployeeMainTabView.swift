import SwiftUI

struct EmployeeMainTabView: View {
    var body: some View {
        TabView {
            EmployeeUserListView()
                .tabItem {
                    Label("Пользователи", systemImage: "person.3")
                }

            EmployeeAllAccountsView()
                .tabItem {
                    Label("Счета", systemImage: "creditcard")
                }

            EmployeeTariffListView()
                .tabItem {
                    Label("Тарифы", systemImage: "percent")
                }

            EmployeeSettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
        }
    }
}
