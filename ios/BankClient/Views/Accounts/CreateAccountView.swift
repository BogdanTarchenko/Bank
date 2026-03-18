import SwiftUI
import BankShared

struct CreateAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AccountListViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Валюта") {
                    Picker("Валюта", selection: $viewModel.selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.rawValue) \(currency.symbol)").tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let error = viewModel.actionError {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }

                Section {
                    Button("Создать счёт") {
                        Task { await viewModel.createAccount() }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Новый счёт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .loadingOverlay(viewModel.isActionLoading)
        }
    }
}
