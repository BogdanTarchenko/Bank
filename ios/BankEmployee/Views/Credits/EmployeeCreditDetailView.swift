import SwiftUI
import BankShared

struct EmployeeCreditDetailView: View {
    @EnvironmentObject private var container: EmployeeDependencyContainer
    @State private var viewModel: EmployeeCreditDetailViewModel?
    let credit: Credit

    var body: some View {
        Group {
            if let viewModel {
                List {
                    Section("Информация") {
                        LabeledContent("ID пользователя", value: "\(viewModel.credit.userId)")
                        LabeledContent("Тариф", value: viewModel.credit.tariffName)
                        LabeledContent("Статус") {
                            StatusBadge(creditStatus: viewModel.credit.status)
                        }
                        LabeledContent("Сумма", value: viewModel.credit.principal.formattedPlain())
                        LabeledContent("Остаток долга", value: viewModel.credit.remaining.formattedPlain())
                        if let accrued = viewModel.credit.accruedInterest, accrued > 0 {
                            LabeledContent("Начисленные %", value: accrued.formattedPlain())
                        }
                        LabeledContent("Ставка", value: "\(viewModel.credit.interestRate.formattedPlain())%")
                        LabeledContent("Срок", value: "\(viewModel.credit.termDays) дн.")
                        LabeledContent("Ежедневный платёж", value: viewModel.credit.dailyPayment.formattedPlain())
                        LabeledContent("Открыт", value: viewModel.credit.createdAt.toShortDate())
                        if let closedAt = viewModel.credit.closedAt {
                            LabeledContent("Закрыт", value: closedAt.toShortDate())
                        }
                    }

                    Section("График платежей") {
                        if viewModel.isLoadingPayments {
                            ProgressView().frame(maxWidth: .infinity)
                        } else if viewModel.payments.isEmpty {
                            Text("Нет платежей").foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.payments) { payment in
                                PaymentRow(payment: payment)
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Section {
                            Text(error).foregroundStyle(.red).font(.caption)
                        }
                    }
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle("Кредит #\(credit.id)")
        .task {
            if viewModel == nil {
                viewModel = EmployeeCreditDetailViewModel(
                    credit: credit,
                    useCase: container.creditUseCase
                )
            }
            await viewModel?.loadPayments()
        }
    }
}
