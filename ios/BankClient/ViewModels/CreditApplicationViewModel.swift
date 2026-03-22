import SwiftUI
import BankShared

@MainActor
@Observable
final class CreditApplicationViewModel {
    var tariffs: [Tariff] = []
    var selectedTariff: Tariff?
    var accounts: [Account] = []
    var selectedAccount: Account?
    var amountText = ""
    var termDays = 30
    var isLoading = false
    var errorMessage: String?
    var success = false

    private let creditUseCase: CreditUseCase
    private let accountUseCase: AccountUseCase
    private let userId: Int64

    init(creditUseCase: CreditUseCase, accountUseCase: AccountUseCase, userId: Int64) {
        self.creditUseCase = creditUseCase
        self.accountUseCase = accountUseCase
        self.userId = userId
    }

    var termRange: ClosedRange<Int> {
        guard let tariff = selectedTariff else { return 1...365 }
        let min = tariff.minTermDays ?? 1
        let max = tariff.maxTermDays ?? 365
        return min...max
    }

    var isValid: Bool {
        selectedTariff != nil && selectedAccount != nil && Validator.isValidAmount(amountText) && termRange.contains(termDays)
    }

    func load() async {
        isLoading = true
        do {
            async let t = creditUseCase.getTariffs()
            async let a = accountUseCase.getAccounts()
            tariffs = try await t.filter(\.active)
            accounts = try await a.filter { !$0.isClosed && $0.accountType == .PERSONAL }
            selectedTariff = tariffs.first
            selectedAccount = accounts.first
            if let tariff = selectedTariff {
                termDays = tariff.minTermDays ?? 30
            }
        } catch {
            errorMessage = error.userMessage
        }
        isLoading = false
    }

    func apply() async {
        guard let tariff = selectedTariff, let account = selectedAccount,
              let amount = Decimal(string: amountText) else { return }
        isLoading = true
        errorMessage = nil
        do {
            _ = try await creditUseCase.createCredit(request: CreateCreditRequest(
                accountId: account.id, tariffId: tariff.id,
                amount: amount, termDays: termDays
            ))
            success = true
        } catch {
            errorMessage = error.userMessage
        }
        isLoading = false
    }
}
