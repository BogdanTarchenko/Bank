import SwiftUI
import BankShared

struct EmployeeRootView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                EmployeeMainTabView()
            } else {
                EmployeeLoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}
