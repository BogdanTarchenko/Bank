import SwiftUI
import BankShared

@MainActor
@Observable
final class CreditListViewModel {
    var state: LoadingState<[Credit]> = .idle
    private let useCase: CreditUseCase
    private let userId: Int64

    init(useCase: CreditUseCase, userId: Int64) {
        self.useCase = useCase
        self.userId = userId
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await useCase.getCredits(userId: userId))
        } catch {
            state = .error((error as? NetworkError)?.localizedDescription ?? error.localizedDescription)
        }
    }
}
