import SwiftUI
import BankShared

@MainActor
@Observable
final class CreditDetailViewModel {
    var credit: Credit
    var payments: [Payment] = []
    var isLoadingPayments = false
    var repayAmount = ""
    var isRepaying = false
    var errorMessage: String?
    var successMessage: String?

    private let useCase: CreditUseCase

    init(credit: Credit, useCase: CreditUseCase) {
        self.credit = credit
        self.useCase = useCase
    }

    func loadPayments() async {
        isLoadingPayments = true
        do {
            payments = try await useCase.getPayments(creditId: credit.id)
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isLoadingPayments = false
    }

    func repay() async {
        guard let amount = Decimal(string: repayAmount), amount > 0 else { return }
        isRepaying = true
        errorMessage = nil
        do {
            credit = try await useCase.repay(creditId: credit.id, amount: amount)
            successMessage = "Платёж отправлен"
            repayAmount = ""
            await loadPayments()
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isRepaying = false
    }
}
