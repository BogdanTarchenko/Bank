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
                    infoSection(viewModel)
                    debtSection(viewModel)
                    repaySection(viewModel)
                    messagesSection(viewModel)
                    paymentsSection(viewModel)
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

    @ViewBuilder
    private func infoSection(_ vm: CreditDetailViewModel) -> some View {
        Section {
            LabeledContent("Тариф", value: vm.credit.tariffName)
            LabeledContent("Статус") { StatusBadge(creditStatus: vm.credit.status) }
            LabeledContent("Ставка", value: "\(vm.credit.interestRate.formattedPlain())% годовых")
            LabeledContent("Срок", value: "\(vm.credit.termDays) дн.")
            LabeledContent("Ежедневный платёж", value: vm.credit.dailyPayment.formattedPlain())
        }
    }

    @ViewBuilder
    private func debtSection(_ vm: CreditDetailViewModel) -> some View {
        let accrued = vm.credit.accruedInterest ?? 0
        Section("Задолженность") {
            LabeledContent("Основной долг", value: vm.credit.principal.formattedPlain())
            LabeledContent("Остаток долга", value: vm.credit.remaining.formattedPlain())
            if accrued > 0 {
                LabeledContent("Начисленные %", value: accrued.formattedPlain())
                LabeledContent("Итого к оплате", value: (vm.credit.remaining + accrued).formattedPlain())
            }
        }
    }

    @ViewBuilder
    private func repaySection(_ vm: CreditDetailViewModel) -> some View {
        if vm.credit.status == .ACTIVE {
            Section("Погашение") {
                AmountTextField(text: Binding(
                    get: { vm.repayAmount },
                    set: { vm.repayAmount = $0 }
                ))
                Button("Оплатить") {
                    Task { await vm.repay() }
                }
                .disabled(vm.repayAmount.isEmpty)
            }
        }
    }

    @ViewBuilder
    private func messagesSection(_ vm: CreditDetailViewModel) -> some View {
        if let error = vm.errorMessage {
            Section { Text(error).foregroundStyle(.red).font(.caption) }
        }
        if let success = vm.successMessage {
            Section { Text(success).foregroundStyle(.green).font(.caption) }
        }
    }

    @ViewBuilder
    private func paymentsSection(_ vm: CreditDetailViewModel) -> some View {
        Section("Платежи") {
            if vm.payments.isEmpty && !vm.isLoadingPayments {
                Text("Нет платежей").foregroundStyle(.secondary)
            } else {
                ForEach(vm.payments) { PaymentRow(payment: $0) }
            }
            if vm.isLoadingPayments {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
    }
}
