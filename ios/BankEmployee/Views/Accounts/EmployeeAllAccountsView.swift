import SwiftUI
import BankShared

struct EmployeeAllAccountsView: View {
    @EnvironmentObject private var container: EmployeeDependencyContainer
    @State private var viewModel: EmployeeAccountListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LoadableView(state: viewModel.state, onRetry: { Task { await viewModel.load() } }) { _ in
                        List(viewModel.filteredAccounts) { account in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("Счёт #\(account.id)").font(.headline)
                                        CurrencyBadge(account.currency)
                                        if account.accountType == .MASTER {
                                            StatusBadge("Master", color: .purple)
                                        }
                                    }
                                    Text("Пользователь: \(account.userId)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(account.balance.formatted(currency: account.currency))
                                        .font(.subheadline.bold().monospacedDigit())
                                    if account.isClosed {
                                        StatusBadge("Закрыт", color: .gray)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .searchable(text: Binding(
                            get: { viewModel.searchText },
                            set: { viewModel.searchText = $0 }
                        ), prompt: "Поиск по ID счёта или пользователя")
                    }
                } else {
                    LoadingView()
                }
            }
            .navigationTitle("Все счета")
            .refreshable { await viewModel?.load() }
            .task {
                if viewModel == nil {
                    viewModel = EmployeeAccountListViewModel(
                        useCase: container.accountUseCase
                    )
                }
                await viewModel?.load()
            }
        }
    }
}
