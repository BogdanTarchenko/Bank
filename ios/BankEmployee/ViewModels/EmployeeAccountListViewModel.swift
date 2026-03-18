import SwiftUI
import BankShared

@MainActor
@Observable
final class EmployeeAccountListViewModel {
    var state: LoadingState<[Account]> = .idle
    var searchText = ""

    private let useCase: AccountViewUseCase

    init(useCase: AccountViewUseCase) {
        self.useCase = useCase
    }

    var filteredAccounts: [Account] {
        guard let accounts = state.value else { return [] }
        if searchText.isEmpty { return accounts }
        return accounts.filter {
            "\($0.id)".contains(searchText)
            || "\($0.userId)".contains(searchText)
        }
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await useCase.getAllAccounts())
        } catch {
            state = .error((error as? NetworkError)?.localizedDescription ?? error.localizedDescription)
        }
    }
}
