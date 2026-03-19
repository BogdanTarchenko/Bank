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
        let previousState = state
        if case .loaded = state {} else { state = .loading }
        do {
            state = .loaded(try await useCase.getCredits(userId: userId))
        } catch is CancellationError {
            state = previousState
        } catch {
            state = .error((error as? NetworkError)?.localizedDescription ?? error.localizedDescription)
        }
    }
}
