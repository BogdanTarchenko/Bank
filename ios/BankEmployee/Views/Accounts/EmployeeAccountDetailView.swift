import SwiftUI
import BankShared

struct EmployeeAccountDetailView: View {
    @EnvironmentObject private var container: EmployeeDependencyContainer
    @State private var viewModel: EmployeeAccountDetailViewModel?
    let account: Account

    var body: some View {
        Group {
            if let viewModel {
                List {
                    Section("Информация") {
                        LabeledContent("ID счёта", value: "\(viewModel.account.id)")
                        LabeledContent("Пользователь", value: "ID \(viewModel.account.userId)")
                        LabeledContent("Валюта") { CurrencyBadge(viewModel.account.currency) }
                        LabeledContent("Баланс", value: viewModel.account.balance.formatted(currency: viewModel.account.currency))
                        LabeledContent("Тип") {
                            Text(viewModel.account.accountType == .MASTER ? "Мастер" : "Личный")
                                .foregroundStyle(viewModel.account.accountType == .MASTER ? .purple : .primary)
                        }
                        LabeledContent("Статус") {
                            StatusBadge(
                                viewModel.account.isClosed ? "Закрыт" : "Активен",
                                color: viewModel.account.isClosed ? .gray : .green
                            )
                        }
                        LabeledContent("Открыт", value: viewModel.account.createdAt.toShortDate())
                    }

                    Section("История операций") {
                        if viewModel.isLoadingOperations && viewModel.operations.isEmpty {
                            ProgressView().frame(maxWidth: .infinity)
                        } else if viewModel.operations.isEmpty {
                            Text("Нет операций").foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.operations) { operation in
                                OperationRow(operation: operation)
                            }
                            if viewModel.hasMorePages {
                                Button("Загрузить ещё") {
                                    Task { await viewModel.loadMore() }
                                }
                                .frame(maxWidth: .infinity)
                                if viewModel.isLoadingOperations {
                                    ProgressView().frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Section {
                            Text(error).foregroundStyle(.red).font(.caption)
                        }
                    }
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Счёт #\(account.id)")
        .task {
            if viewModel == nil {
                viewModel = EmployeeAccountDetailViewModel(
                    account: account,
                    useCase: container.accountUseCase
                )
            }
            await viewModel?.loadOperations()
        }
    }
}
