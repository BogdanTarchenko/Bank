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
                    .foregroundStyle(Color.appPrimary)
                Text("Bank Employee")
                    .font(.largeTitle.bold())
                Text("Панель сотрудника")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let deniedMessage = authManager.accessDeniedMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(deniedMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 32)
            }

            Button {
                Task {
                    isLoading = true
                    errorMessage = nil
                    do {
                        try await authManager.login()
                    } catch {
                        errorMessage = error.userMessage
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
