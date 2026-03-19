import SwiftUI
import BankShared

struct AccountListView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(AppState.self) private var appState
    @State private var viewModel: AccountListViewModel?

    private var visibleAccounts: [Account] {
        guard let accounts = viewModel?.state.value else { return [] }
        if appState.showHiddenAccounts {
            return accounts
        }
        return accounts.filter { !appState.isHidden(accountId: $0.id) }
    }

    private var hiddenCount: Int {
        guard let accounts = viewModel?.state.value else { return 0 }
        return accounts.filter { appState.isHidden(accountId: $0.id) }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LoadableView(state: viewModel.state) { accounts in
                        let visible = appState.showHiddenAccounts
                            ? accounts
                            : accounts.filter { !appState.isHidden(accountId: $0.id) }
                        if visible.isEmpty && !accounts.isEmpty {
                            VStack(spacing: 12) {
                                EmptyStateView(icon: "eye.slash", title: "Все счета скрыты", message: "Нажмите кнопку ниже, чтобы показать")
                                Button("Показать скрытые счета") {
                                    appState.showHiddenAccounts = true
                                }
                                .buttonStyle(.bordered)
                            }
                        } else if visible.isEmpty {
                            EmptyStateView(icon: "creditcard", title: "Нет счетов", message: "Создайте первый счёт")
                        } else {
                            List {
                                ForEach(visible) { account in
                                    NavigationLink(value: account.id) {
                                        AccountRow(
                                            account: account,
                                            isHidden: appState.isHidden(accountId: account.id)
                                        )
                                    }
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
                if hiddenCount > 0 {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            appState.showHiddenAccounts.toggle()
                        } label: {
                            Image(systemName: appState.showHiddenAccounts ? "eye" : "eye.slash")
                        }
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
            .onAppear {
                if viewModel != nil {
                    Task { await viewModel?.load() }
                }
            }
            .task(id: appState.currentUserId) {
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
    var isHidden: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Счёт #\(account.id)")
                        .font(.headline)
                    CurrencyBadge(account.currency)
                    if isHidden {
                        Image(systemName: "eye.slash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(account.balance.formatted(currency: account.currency))
                    .font(.title3.bold())
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(isHidden ? 0.5 : 1.0)
    }
}
