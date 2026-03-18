import SwiftUI
import BankShared

struct AccountListView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(AppState.self) private var appState
    @State private var viewModel: AccountListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LoadableView(state: viewModel.state) { accounts in
                        if accounts.isEmpty {
                            EmptyStateView(icon: "creditcard", title: "Нет счетов", message: "Создайте первый счёт")
                        } else {
                            List(accounts) { account in
                                NavigationLink(value: account.id) {
                                    AccountRow(account: account)
                                }
                            }
                        }
                    }
                    .navigationDestination(for: Int64.self) { accountId in
                        if let account = viewModel.state.value?.first(where: { $0.id == accountId }) {
                            AccountDetailView(account: account)
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            .navigationTitle("Счета")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel?.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    NavigationLink {
                        if let accounts = viewModel?.state.value {
                            TransferView(accounts: accounts)
                        }
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showCreateSheet ?? false },
                set: { viewModel?.showCreateSheet = $0 }
            )) {
                if let viewModel {
                    CreateAccountView(viewModel: viewModel)
                }
            }
            .refreshable {
                await viewModel?.load()
            }
            .task {
                guard let userId = appState.currentUserId else { return }
                if viewModel == nil {
                    viewModel = AccountListViewModel(
                        useCase: container.accountUseCase,
                        userId: userId
                    )
                }
                await viewModel?.load()
            }
        }
    }
}

private struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Счёт #\(account.id)")
                        .font(.headline)
                    CurrencyBadge(account.currency)
                }
                Text(account.balance.formatted(currency: account.currency))
                    .font(.title3.bold())
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
