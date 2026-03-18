import SwiftUI
import BankShared

struct AccountDetailView: View {
    @State private var viewModel: AccountDetailViewModel

    init(account: Account) {
        _viewModel = State(initialValue: AccountDetailViewModel(
            account: account,
            useCase: AccountUseCase(client: HTTPClient(baseURL: ClientConfiguration.bffBaseURL))
        ))
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Text(viewModel.account.balance.formatted(currency: viewModel.account.currency))
                        .font(.largeTitle.bold())
                    CurrencyBadge(viewModel.account.currency)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Операция") {
                AmountTextField(text: $viewModel.amountText, currency: viewModel.account.currency)
                HStack(spacing: 12) {
                    Button("Пополнить") {
                        Task { await viewModel.deposit() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appSuccess)

                    Button("Снять") {
                        Task { await viewModel.withdraw() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appDanger)
                }
                .disabled(viewModel.amountText.isEmpty)
            }

            if let error = viewModel.actionError {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
            if let success = viewModel.actionSuccess {
                Section {
                    Text(success).foregroundStyle(.green).font(.caption)
                }
            }

            Section("История операций") {
                if viewModel.operations.isEmpty && !viewModel.isLoadingOperations {
                    Text("Нет операций").foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.operations) { op in
                        OperationRow(operation: op)
                    }
                    if viewModel.hasMorePages {
                        Button("Загрузить ещё") {
                            Task { await viewModel.loadMoreOperations() }
                        }
                    }
                }
                if viewModel.isLoadingOperations {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }

            Section {
                Button("Закрыть счёт", role: .destructive) {
                    Task { await viewModel.closeAccount() }
                }
                .disabled(viewModel.account.balance != 0)
            }
        }
        .navigationTitle("Счёт #\(viewModel.account.id)")
        .loadingOverlay(viewModel.isActionLoading)
        .task {
            await viewModel.loadOperations()
        }
    }
}
