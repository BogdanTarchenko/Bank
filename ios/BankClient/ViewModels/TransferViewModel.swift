import SwiftUI
import BankShared

enum TransferDestination: String, CaseIterable {
    case own = "Свой счёт"
    case other = "Чужой счёт"
}

@MainActor
@Observable
final class TransferViewModel {
    var fromAccount: Account?
    var toAccount: Account?
    var destinationType: TransferDestination = .own
    var externalAccountId = ""
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
        guard fromAccount != nil, Validator.isValidAmount(amountText) else { return false }
        switch destinationType {
        case .own:
            return toAccount != nil && fromAccount?.id != toAccount?.id
        case .other:
            guard let id = Int64(externalAccountId) else { return false }
            return id != fromAccount?.id
        }
    }

    var targetAccountId: Int64? {
        switch destinationType {
        case .own:
            return toAccount?.id
        case .other:
            return Int64(externalAccountId)
        }
    }

    func transfer() async {
        guard let from = fromAccount,
              let toId = targetAccountId,
              let amount = Decimal(string: amountText) else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await useCase.transfer(from: from.id, to: toId, amount: amount)
            success = true
        } catch {
            errorMessage = error.userMessage
        }
        isLoading = false
    }
}
