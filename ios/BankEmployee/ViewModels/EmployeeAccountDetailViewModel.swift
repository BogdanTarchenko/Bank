import SwiftUI
import BankShared

@MainActor
@Observable
final class EmployeeAccountDetailViewModel {
    var account: Account
    var operations: [BankShared.Operation] = []
    var isLoadingOperations = false
    var hasMorePages = true
    var currentPage = 0
    var errorMessage: String?

    private let useCase: AccountViewUseCase

    init(account: Account, useCase: AccountViewUseCase) {
        self.account = account
        self.useCase = useCase
    }

    func loadOperations() async {
        isLoadingOperations = true
        currentPage = 0
        do {
            let page = try await useCase.getOperations(accountId: account.id, page: 0)
            operations = page.content
            hasMorePages = page.hasNext
        } catch is CancellationError {
        } catch {
            errorMessage = error.userMessage
        }
        isLoadingOperations = false
    }

    func loadMore() async {
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
}
