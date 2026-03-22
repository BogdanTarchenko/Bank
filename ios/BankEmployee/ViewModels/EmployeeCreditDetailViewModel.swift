import SwiftUI
import BankShared

@MainActor
@Observable
final class EmployeeCreditDetailViewModel {
    var credit: Credit
    var payments: [Payment] = []
    var isLoadingPayments = false
    var errorMessage: String?

    private let useCase: EmployeeCreditUseCase

    init(credit: Credit, useCase: EmployeeCreditUseCase) {
        self.credit = credit
        self.useCase = useCase
    }

    func loadPayments() async {
        isLoadingPayments = true
        do {
            payments = try await useCase.getPayments(creditId: credit.id)
        } catch {
            errorMessage = error.userMessage
        }
        isLoadingPayments = false
    }
}
