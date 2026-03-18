import SwiftUI
import BankShared

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        Form {
            Section("Личные данные") {
                TextField("Имя", text: $viewModel.firstName)
                    .textContentType(.givenName)
                TextField("Фамилия", text: $viewModel.lastName)
                    .textContentType(.familyName)
                TextField("Телефон", text: $viewModel.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            Section("Учётные данные") {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Пароль (мин. 6 символов)", text: $viewModel.password)
                    .textContentType(.newPassword)
            }

            Section {
                Button {
                    Task { await viewModel.register() }
                } label: {
                    Text("Зарегистрироваться")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.isRegisterFormValid)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Регистрация")
        .loadingOverlay(viewModel.isLoading)
        .alert("Успешно", isPresented: $viewModel.registrationSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Аккаунт создан. Теперь войдите.")
        }
    }
}
