import SwiftUI
import BankShared

struct CreateTariffView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TariffListViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название тарифа", text: $viewModel.name)
                    TextField("Процентная ставка (%)", text: $viewModel.interestRate)
                        .keyboardType(.decimalPad)
                }

                Section("Лимиты суммы (опционально)") {
                    TextField("Минимальная сумма", text: $viewModel.minAmount)
                        .keyboardType(.decimalPad)
                    TextField("Максимальная сумма", text: $viewModel.maxAmount)
                        .keyboardType(.decimalPad)
                }

                Section("Лимиты срока (опционально)") {
                    TextField("Минимальный срок (дни)", text: $viewModel.minTermDays)
                        .keyboardType(.numberPad)
                    TextField("Максимальный срок (дни)", text: $viewModel.maxTermDays)
                        .keyboardType(.numberPad)
                }

                if let error = viewModel.createError {
                    Section { Text(error).foregroundStyle(.red).font(.caption) }
                }

                Section {
                    Button("Создать тариф") {
                        Task { await viewModel.createTariff() }
                    }
                    .disabled(!viewModel.isCreateFormValid)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Новый тариф")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .loadingOverlay(viewModel.isCreating)
        }
    }
}
