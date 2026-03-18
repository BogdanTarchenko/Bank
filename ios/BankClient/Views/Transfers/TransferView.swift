import SwiftUI
import BankShared

struct TransferView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TransferViewModel?
    let accounts: [Account]

    var body: some View {
        Group {
            if let viewModel {
                Form {
                    Section("Откуда") {
                        Picker("Счёт списания", selection: Binding(
                            get: { viewModel.fromAccount },
                            set: { viewModel.fromAccount = $0 }
                        )) {
                            ForEach(viewModel.accounts) { account in
                                Text("Счёт #\(account.id) — \(account.balance.formatted(currency: account.currency))")
                                    .tag(account as Account?)
                            }
                        }
                    }

                    Section("Куда") {
                        Picker("Счёт зачисления", selection: Binding(
                            get: { viewModel.toAccount },
                            set: { viewModel.toAccount = $0 }
                        )) {
                            Text("Выберите").tag(nil as Account?)
                            ForEach(viewModel.accounts.filter { $0.id != viewModel.fromAccount?.id }) { account in
                                Text("Счёт #\(account.id) — \(account.currency.rawValue)")
                                    .tag(account as Account?)
                            }
                        }
                    }

                    Section("Сумма") {
                        AmountTextField(text: Binding(
                            get: { viewModel.amountText },
                            set: { viewModel.amountText = $0 }
                        ), currency: viewModel.fromAccount?.currency)
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
                .loadingOverlay(viewModel.isLoading)
                .alert("Успешно", isPresented: Binding(
                    get: { viewModel.success },
                    set: { viewModel.success = $0 }
                )) {
                    Button("OK") { dismiss() }
                } message: {
                    Text("Перевод отправлен")
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Перевод")
        .task {
            if viewModel == nil {
                viewModel = TransferViewModel(accounts: accounts, useCase: container.transferUseCase)
            }
        }
    }
}
