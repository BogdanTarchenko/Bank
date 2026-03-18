import SwiftUI
import BankShared

struct TransferView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TransferViewModel

    init(accounts: [Account]) {
        _viewModel = State(initialValue: TransferViewModel(
            accounts: accounts,
            useCase: TransferUseCase(client: HTTPClient(baseURL: ClientConfiguration.bffBaseURL))
        ))
    }

    var body: some View {
        Form {
            Section("Откуда") {
                Picker("Счёт списания", selection: $viewModel.fromAccount) {
                    ForEach(viewModel.accounts) { account in
                        Text("Счёт #\(account.id) — \(account.balance.formatted(currency: account.currency))")
                            .tag(account as Account?)
                    }
                }
            }

            Section("Куда") {
                Picker("Счёт зачисления", selection: $viewModel.toAccount) {
                    Text("Выберите").tag(nil as Account?)
                    ForEach(viewModel.accounts.filter { $0.id != viewModel.fromAccount?.id }) { account in
                        Text("Счёт #\(account.id) — \(account.currency.rawValue)")
                            .tag(account as Account?)
                    }
                }
            }

            Section("Сумма") {
                AmountTextField(text: $viewModel.amountText, currency: viewModel.fromAccount?.currency)
            }

            if viewModel.fromAccount?.currency != viewModel.toAccount?.currency,
               let from = viewModel.fromAccount, let to = viewModel.toAccount {
                Section {
                    Text("Кросс-валютный перевод: \(from.currency.rawValue) → \(to.currency.rawValue). Конвертация по текущему курсу.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = viewModel.errorMessage {
                Section { Text(error).foregroundStyle(.red).font(.caption) }
            }

            Section {
                Button("Перевести") {
                    Task { await viewModel.transfer() }
                }
                .disabled(!viewModel.isValid)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Перевод")
        .loadingOverlay(viewModel.isLoading)
        .alert("Успешно", isPresented: $viewModel.success) {
            Button("OK") { dismiss() }
        } message: {
            Text("Перевод отправлен")
        }
    }
}
