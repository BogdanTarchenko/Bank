import SwiftUI
import BankShared

@MainActor
@Observable
final class AccountListViewModel {
    var state: LoadingState<[Account]> = .idle
    var showCreateSheet = false
    var selectedCurrency: Currency = .RUB
    var actionError: String?
    var isActionLoading = false

    private let useCase: AccountUseCase
    private let userId: Int64

    init(useCase: AccountUseCase, userId: Int64) {
        self.useCase = useCase
        self.userId = userId
    }

    func load() async {
        state = .loading
        do {
            let accounts = try await useCase.getAccounts(userId: userId)
            state = .loaded(accounts.filter { !$0.isClosed && $0.accountType == .PERSONAL })
        } catch {
            state = .error((error as? NetworkError)?.localizedDescription ?? error.localizedDescription)
        }
    }

    func createAccount() async {
        isActionLoading = true
        actionError = nil
        do {
            _ = try await useCase.createAccount(userId: userId, currency: selectedCurrency)
            showCreateSheet = false
            await load()
        } catch {
            actionError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isActionLoading = false
    }
}
