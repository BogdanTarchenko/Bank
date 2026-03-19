import SwiftUI
import BankShared

@MainActor
@Observable
final class AccountDetailViewModel {
    var account: Account
    var operations: [BankShared.Operation] = []
    var isLoadingOperations = false
    var amountText = ""
    var isActionLoading = false
    var actionError: String?
    var actionSuccess: String?
    var currentPage = 0
    var hasMorePages = true

    private let useCase: AccountUseCase

    init(account: Account, useCase: AccountUseCase) {
        self.account = account
        self.useCase = useCase
    }

    func loadOperations() async {
        if operations.isEmpty { isLoadingOperations = true }
        currentPage = 0
        do {
            let page = try await useCase.getOperations(accountId: account.id, page: 0)
            operations = page.content
            hasMorePages = page.hasNext
        } catch is CancellationError {
            // Не меняем состояние при отмене
        } catch {
            actionError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isLoadingOperations = false
    }

    func loadMoreOperations() async {
        guard hasMorePages, !isLoadingOperations else { return }
        isLoadingOperations = true
        currentPage += 1
        do {
            let page = try await useCase.getOperations(accountId: account.id, page: currentPage)
            operations.append(contentsOf: page.content)
            hasMorePages = page.hasNext
        } catch {
            currentPage -= 1
        }
        isLoadingOperations = false
    }

    func deposit() async {
        guard let amount = Decimal(string: amountText), amount > 0 else { return }
        isActionLoading = true
        actionError = nil
        do {
            try await useCase.deposit(accountId: account.id, amount: amount)
            actionSuccess = "Пополнение отправлено"
            amountText = ""
            await refreshAccount()
        } catch {
            actionError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isActionLoading = false
    }

    func withdraw() async {
        guard let amount = Decimal(string: amountText), amount > 0 else { return }
        isActionLoading = true
        actionError = nil
        do {
            try await useCase.withdraw(accountId: account.id, amount: amount)
            actionSuccess = "Снятие отправлено"
            amountText = ""
            await refreshAccount()
        } catch {
            actionError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isActionLoading = false
    }

    func closeAccount() async {
        isActionLoading = true
        actionError = nil
        do {
            try await useCase.closeAccount(id: account.id)
            actionSuccess = "Счёт закрыт"
        } catch {
            actionError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isActionLoading = false
    }

    private func refreshAccount() async {
        do {
            account = try await useCase.getAccount(id: account.id)
            await loadOperations()
        } catch {}
    }
}
