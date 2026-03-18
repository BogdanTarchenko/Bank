import SwiftUI
import BankShared

struct EmployeeLoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.appPrimary)
                Text("Bank Employee")
                    .font(.largeTitle.bold())
                Text("Панель сотрудника")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    isLoading = true
                    errorMessage = nil
                    do {
                        try await authManager.login()
                    } catch {
                        errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                    }
                    isLoading = false
                }
            } label: {
                Text("Войти")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .loadingOverlay(isLoading)
    }
}
