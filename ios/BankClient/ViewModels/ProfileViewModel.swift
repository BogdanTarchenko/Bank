import SwiftUI
import BankShared

@MainActor
@Observable
final class ProfileViewModel {
    var state: LoadingState<User> = .idle
    var creditRating: CreditRating?
    private let userUseCase: UserUseCase
    private let creditUseCase: CreditUseCase
    private let userId: Int64

    init(userUseCase: UserUseCase, creditUseCase: CreditUseCase, userId: Int64) {
        self.userUseCase = userUseCase
        self.creditUseCase = creditUseCase
        self.userId = userId
    }

    func load() async {
        state = .loading
        do {
            async let user = userUseCase.getUser(id: userId)
            async let rating = creditUseCase.getCreditRating(userId: userId)
            state = .loaded(try await user)
            creditRating = try? await rating
        } catch {
            state = .error((error as? NetworkError)?.localizedDescription ?? error.localizedDescription)
        }
    }
}
