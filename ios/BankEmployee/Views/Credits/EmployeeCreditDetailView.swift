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
                    infoSection(viewModel)
                    debtSection(viewModel)
                    paymentsSection(viewModel)
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

    @ViewBuilder
    private func infoSection(_ vm: EmployeeCreditDetailViewModel) -> some View {
        Section("Информация") {
            LabeledContent("ID пользователя", value: "\(vm.credit.userId)")
            LabeledContent("Тариф", value: vm.credit.tariffName)
            LabeledContent("Статус") { StatusBadge(creditStatus: vm.credit.status) }
            LabeledContent("Ставка", value: "\(vm.credit.interestRate.formattedPlain())% годовых")
            LabeledContent("Срок", value: "\(vm.credit.termDays) дн.")
            LabeledContent("Ежедневный платёж", value: vm.credit.dailyPayment.formattedPlain())
            LabeledContent("Открыт", value: vm.credit.createdAt.toShortDate())
            if let closedAt = vm.credit.closedAt {
                LabeledContent("Закрыт", value: closedAt.toShortDate())
            }
        }
    }

    @ViewBuilder
    private func debtSection(_ vm: EmployeeCreditDetailViewModel) -> some View {
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
    private func paymentsSection(_ vm: EmployeeCreditDetailViewModel) -> some View {
        Section("График платежей") {
            if vm.isLoadingPayments {
                ProgressView().frame(maxWidth: .infinity)
            } else if vm.payments.isEmpty {
                Text("Нет платежей").foregroundStyle(.secondary)
            } else {
                ForEach(vm.payments) { PaymentRow(payment: $0) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmployeeCreditDetailView(credit: Credit(
            id: 1, userId: 42, accountId: 10, tariffId: 1,
            tariffName: "Стандарт", principal: 50000, remaining: 45000,
            accruedInterest: 200, interestRate: 0.15, termDays: 365,
            dailyPayment: 150, status: .ACTIVE,
            createdAt: "2026-03-01T10:00:00", closedAt: nil
        ))
        .environmentObject(EmployeeDependencyContainer())
    }
}
