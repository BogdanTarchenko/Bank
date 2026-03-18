import SwiftUI
import BankShared

struct CreditDetailView: View {
    @State private var viewModel: CreditDetailViewModel

    init(credit: Credit) {
        _viewModel = State(initialValue: CreditDetailViewModel(
            credit: credit,
            useCase: CreditUseCase(client: HTTPClient(baseURL: ClientConfiguration.bffBaseURL))
        ))
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Тариф", value: viewModel.credit.tariffName)
                LabeledContent("Сумма кредита", value: viewModel.credit.principal.formattedPlain())
                LabeledContent("Остаток", value: viewModel.credit.remaining.formattedPlain())
                LabeledContent("Ставка", value: "\(viewModel.credit.interestRate.formattedPlain())%")
                LabeledContent("Срок", value: "\(viewModel.credit.termDays) дн.")
                LabeledContent("Ежедневный платёж", value: viewModel.credit.dailyPayment.formattedPlain())
                LabeledContent("Статус") { StatusBadge(creditStatus: viewModel.credit.status) }
            }

            if viewModel.credit.status == .ACTIVE {
                Section("Погашение") {
                    AmountTextField(text: $viewModel.repayAmount)
                    Button("Оплатить") {
                        Task { await viewModel.repay() }
                    }
                    .disabled(viewModel.repayAmount.isEmpty)
                }
            }

            if let error = viewModel.errorMessage {
                Section { Text(error).foregroundStyle(.red).font(.caption) }
            }
            if let success = viewModel.successMessage {
                Section { Text(success).foregroundStyle(.green).font(.caption) }
            }

            Section("Платежи") {
                if viewModel.payments.isEmpty && !viewModel.isLoadingPayments {
                    Text("Нет платежей").foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.payments) { payment in
                        PaymentRow(payment: payment)
                    }
                }
                if viewModel.isLoadingPayments {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Кредит #\(viewModel.credit.id)")
        .loadingOverlay(viewModel.isRepaying)
        .task { await viewModel.loadPayments() }
    }
}
