import SwiftUI
import BankShared

struct EmployeeTariffListView: View {
    @EnvironmentObject private var container: EmployeeDependencyContainer
    @State private var viewModel: TariffListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LoadableView(state: viewModel.state, onRetry: { Task { await viewModel.load() } }) { tariffs in
                        if tariffs.isEmpty {
                            EmptyStateView(icon: "percent", title: "Нет тарифов", message: "Создайте первый тариф")
                        } else {
                            List(tariffs) { tariff in
                                TariffRow(tariff: tariff)
                            }
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            .navigationTitle("Тарифы")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel?.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showCreateSheet ?? false },
                set: { viewModel?.showCreateSheet = $0 }
            )) {
                if let viewModel {
                    CreateTariffView(viewModel: viewModel)
                }
            }
            .refreshable { await viewModel?.load() }
            .task {
                if viewModel == nil {
                    viewModel = TariffListViewModel(
                        useCase: container.tariffUseCase
                    )
                }
                await viewModel?.load()
            }
        }
    }
}

private struct TariffRow: View {
    let tariff: Tariff

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tariff.name).font(.headline)
                Spacer()
                Text("\(tariff.interestRate.formattedPlain())%")
                    .font(.title3.bold())
                    .foregroundStyle(Color.appPrimary)
            }
            HStack(spacing: 16) {
                if let min = tariff.minAmount, let max = tariff.maxAmount {
                    Text("Сумма: \(min.formattedPlain()) — \(max.formattedPlain())")
                }
                if let min = tariff.minTermDays, let max = tariff.maxTermDays {
                    Text("Срок: \(min) — \(max) дн.")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
