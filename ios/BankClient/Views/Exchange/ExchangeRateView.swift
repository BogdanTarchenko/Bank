import SwiftUI
import BankShared

struct ExchangeRateView: View {
    @State private var viewModel = ExchangeRateViewModel(useCase: ExchangeRateUseCase())

    var body: some View {
        NavigationStack {
            bodyContent
                .navigationTitle("Курсы валют")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await viewModel.load() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .task {
                    await viewModel.load()
                }
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        if viewModel.isLoading && viewModel.rates.isEmpty {
            LoadingView()
        } else if let error = viewModel.errorMessage, viewModel.rates.isEmpty {
            ErrorView(error) {
                Task { await viewModel.load() }
            }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        List {
            Section("Курсы обмена") {
                ForEach(viewModel.rates) { rate in
                    RateRow(rate: rate)
                }
            }
            if let updated = viewModel.lastUpdated {
                Section {
                } footer: {
                    Text("Обновлено: \(updated.formatted(.dateTime.hour().minute().second()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .refreshable {
            await viewModel.load()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

private struct RateRow: View {
    let rate: ExchangeRate

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                CurrencyBadge(rate.from)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                CurrencyBadge(rate.to)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedRate)
                    .font(.title3.bold())
                    .monospacedDigit()
                Text("1 \(rate.from.rawValue) = \(rate.to.symbol)\(formattedRate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedRate: String {
        if rate.rate >= 1 {
            return String(format: "%.4f", rate.rate)
        } else {
            return String(format: "%.6f", rate.rate)
        }
    }
}

#Preview {
    ExchangeRateView()
}
