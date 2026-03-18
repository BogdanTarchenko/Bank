import SwiftUI
import BankShared

struct CreditApplicationView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreditApplicationViewModel?

    var body: some View {
        Group {
            if let viewModel {
                Form {
                    Section("Тариф") {
                        Picker("Тариф", selection: Binding(
                            get: { viewModel.selectedTariff },
                            set: { viewModel.selectedTariff = $0 }
                        )) {
                            ForEach(viewModel.tariffs) { tariff in
                                Text("\(tariff.name) — \(tariff.interestRate.formattedPlain())%")
                                    .tag(tariff as Tariff?)
                            }
                        }
                    }

                    Section("Счёт зачисления") {
                        Picker("Счёт", selection: Binding(
                            get: { viewModel.selectedAccount },
                            set: { viewModel.selectedAccount = $0 }
                        )) {
                            ForEach(viewModel.accounts) { account in
                                Text("Счёт #\(account.id) — \(account.currency.rawValue)")
                                    .tag(account as Account?)
                            }
                        }
                    }

                    Section("Параметры") {
                        AmountTextField("Сумма кредита", text: Binding(
                            get: { viewModel.amountText },
                            set: { viewModel.amountText = $0 }
                        ))
                        Stepper("Срок: \(viewModel.termDays) дн.", value: Binding(
                            get: { viewModel.termDays },
                            set: { viewModel.termDays = $0 }
                        ), in: 1...365)
                    }

                    if let error = viewModel.errorMessage {
                        Section { Text(error).foregroundStyle(.red).font(.caption) }
                    }

                    Section {
                        Button("Оформить кредит") {
                            Task { await viewModel.apply() }
                        }
                        .disabled(!viewModel.isValid)
                        .frame(maxWidth: .infinity)
                    }
                }
                .loadingOverlay(viewModel.isLoading)
                .alert("Кредит оформлен", isPresented: Binding(
                    get: { viewModel.success },
                    set: { viewModel.success = $0 }
                )) {
                    Button("OK") { dismiss() }
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Оформление кредита")
        .task {
            guard let userId = appState.currentUserId else { return }
            if viewModel == nil {
                viewModel = CreditApplicationViewModel(
                    creditUseCase: container.creditUseCase,
                    accountUseCase: container.accountUseCase,
                    userId: userId
                )
            }
            await viewModel?.load()
        }
    }
}
