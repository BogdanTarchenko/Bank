import SwiftUI
import BankShared

@MainActor
@Observable
final class UserListViewModel {
    var state: LoadingState<[User]> = .idle
    var searchText = ""

    private let useCase: UserManagementUseCase

    init(useCase: UserManagementUseCase) {
        self.useCase = useCase
    }

    var filteredUsers: [User] {
        guard let users = state.value else { return [] }
        if searchText.isEmpty { return users }
        return users.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
            || $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await useCase.getAllUsers())
        } catch {
            state = .error((error as? NetworkError)?.localizedDescription ?? error.localizedDescription)
        }
    }
}
