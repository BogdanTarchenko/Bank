import SwiftUI
import BankShared

struct CreditListView: View {
    @EnvironmentObject private var container: DependencyContainer
    @Environment(AppState.self) private var appState
    @State private var viewModel: CreditListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LoadableView(state: viewModel.state, onRetry: { Task { await viewModel.load() } }) { credits in
                        if credits.isEmpty {
                            EmptyStateView(icon: "banknote", title: "Нет кредитов", message: "Оформите кредит")
                        } else {
                            List(credits) { credit in
                                NavigationLink(value: credit.id) {
                                    CreditRow(credit: credit)
                                }
                            }
                        }
                    }
                    .navigationDestination(for: Int64.self) { creditId in
                        if let credit = viewModel.state.value?.first(where: { $0.id == creditId }) {
                            CreditDetailView(credit: credit)
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            .navigationTitle("Кредиты")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        CreditApplicationView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable { await viewModel?.load() }
            .task {
                guard let userId = appState.currentUserId else { return }
                if viewModel == nil {
                    viewModel = CreditListViewModel(
                        useCase: container.creditUseCase,
                        userId: userId
                    )
                }
                await viewModel?.load()
            }
        }
    }
}

private struct CreditRow: View {
    let credit: Credit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(credit.tariffName)
                    .font(.headline)
                Spacer()
                StatusBadge(creditStatus: credit.status)
            }
            Text("Остаток: \(credit.remaining.formattedPlain())")
                .font(.subheadline)
            Text("Ставка: \(credit.interestRate.formattedPlain())%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
