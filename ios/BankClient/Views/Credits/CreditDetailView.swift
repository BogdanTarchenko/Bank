import SwiftUI
import BankShared

struct CreditDetailView: View {
    @EnvironmentObject private var container: DependencyContainer
    @State private var viewModel: CreditDetailViewModel?
    let credit: Credit

    var body: some View {
        Group {
            if let viewModel {
                List {
                    Section {
                        LabeledContent("Тариф", value: viewModel.credit.tariffName)
                        LabeledContent("Сумма кредита", value: viewModel.credit.principal.formattedPlain())
                        LabeledContent("Остаток", value: viewModel.credit.remaining.formattedPlain())
                        if let accrued = viewModel.credit.accruedInterest, accrued > 0 {
                            LabeledContent("Начисленные %", value: accrued.formattedPlain())
                        }
                        LabeledContent("Ставка", value: "\(viewModel.credit.interestRate.formattedPlain())%")
                        LabeledContent("Срок", value: "\(viewModel.credit.termDays) дн.")
                        LabeledContent("Ежедневный платёж", value: viewModel.credit.dailyPayment.formattedPlain())
                        LabeledContent("Статус") { StatusBadge(creditStatus: viewModel.credit.status) }
                    }

                    if viewModel.credit.status == .ACTIVE {
                        Section("Погашение") {
                            AmountTextField(text: Binding(
                                get: { viewModel.repayAmount },
                                set: { viewModel.repayAmount = $0 }
                            ))
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
                .loadingOverlay(viewModel.isRepaying)
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Кредит #\(credit.id)")
        .task {
            if viewModel == nil {
                viewModel = CreditDetailViewModel(credit: credit, useCase: container.creditUseCase)
            }
            await viewModel?.loadPayments()
        }
    }
}
