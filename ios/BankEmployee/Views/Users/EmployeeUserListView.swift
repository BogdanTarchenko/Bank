import SwiftUI
import BankShared

struct EmployeeUserListView: View {
    @EnvironmentObject private var container: EmployeeDependencyContainer
    @State private var viewModel: UserListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LoadableView(state: viewModel.state, onRetry: { Task { await viewModel.load() } }) { _ in
                        List(viewModel.filteredUsers) { user in
                            NavigationLink(value: user.id) {
                                UserRow(user: user)
                            }
                        }
                        .searchable(text: Binding(
                            get: { viewModel.searchText },
                            set: { viewModel.searchText = $0 }
                        ), prompt: "Поиск по имени или email")
                    }
                    .navigationDestination(for: Int64.self) { userId in
                        if let user = viewModel.state.value?.first(where: { $0.id == userId }) {
                            EmployeeUserDetailView(user: user)
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            .navigationTitle("Пользователи")
            .refreshable { await viewModel?.load() }
            .task {
                if viewModel == nil {
                    viewModel = UserListViewModel(useCase: container.userUseCase)
                }
                await viewModel?.load()
            }
        }
    }
}

private struct UserRow: View {
    let user: User

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(user.fullName).font(.headline)
                    if user.blocked {
                        StatusBadge("Заблокирован", color: .red)
                    }
                }
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(user.roles.map(\.rawValue).joined(separator: ", "))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
