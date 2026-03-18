import SwiftUI
import BankShared

@MainActor
@Observable
final class TransferViewModel {
    var fromAccount: Account?
    var toAccount: Account?
    var amountText = ""
    var isLoading = false
    var errorMessage: String?
    var success = false
    let accounts: [Account]

    private let useCase: TransferUseCase

    init(accounts: [Account], useCase: TransferUseCase) {
        self.accounts = accounts
        self.useCase = useCase
        self.fromAccount = accounts.first
    }

    var isValid: Bool {
        fromAccount != nil && toAccount != nil
            && fromAccount?.id != toAccount?.id
            && Validator.isValidAmount(amountText)
    }

    func transfer() async {
        guard let from = fromAccount, let to = toAccount,
              let amount = Decimal(string: amountText) else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await useCase.transfer(from: from.id, to: to.id, amount: amount)
            success = true
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
