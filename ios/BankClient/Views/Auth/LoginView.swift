import SwiftUI
import BankShared

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var viewModel: AuthViewModel

    init(authManager: AuthManager) {
        _viewModel = State(initialValue: AuthViewModel(useCase: AuthUseCase(authManager: authManager)))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.appPrimary)
                    Text("Bank")
                        .font(.largeTitle.bold())
                }

                VStack(spacing: 16) {
                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        Text("Войти")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink {
                        RegisterView(viewModel: viewModel)
                    } label: {
                        Text("Регистрация")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 32)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .loadingOverlay(viewModel.isLoading)
        }
    }
}
