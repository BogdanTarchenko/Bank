import SwiftUI
import BankShared

struct AccountDetailView: View {
    @EnvironmentObject private var container: DependencyContainer
    @State private var viewModel: AccountDetailViewModel?
    let account: Account

    var body: some View {
        Group {
            if let viewModel {
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
                        AmountTextField(text: Binding(
                            get: { viewModel.amountText },
                            set: { viewModel.amountText = $0 }
                        ), currency: viewModel.account.currency)
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
                .loadingOverlay(viewModel.isActionLoading)
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Счёт #\(account.id)")
        .task {
            if viewModel == nil {
                let vm = AccountDetailViewModel(account: account, useCase: container.accountUseCase)
                viewModel = vm
                // WebSocket для real-time обновлений операций
                container.webSocketManager.connect(
                    baseURL: ClientConfiguration.bffBaseURL,
                    token: container.authManager.getAccessToken()
                ) { [weak container] operation in
                    Task { @MainActor in
                        if operation.accountId == account.id {
                            // Добавить новую операцию в начало списка
                            if !vm.operations.contains(where: { $0.id == operation.id }) {
                                vm.operations.insert(operation, at: 0)
                            }
                            // Обновить баланс счёта
                            if let useCase = container?.accountUseCase {
                                if let updated = try? await useCase.getAccount(id: account.id) {
                                    vm.account = updated
                                }
                            }
                        }
                    }
                }
                container.webSocketManager.subscribe(destination: "/topic/accounts/\(account.id)/operations")
            }
            await viewModel?.loadOperations()
        }
        .onDisappear {
            container.webSocketManager.disconnect()
        }
    }
}
