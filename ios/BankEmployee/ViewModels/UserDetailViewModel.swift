import SwiftUI
import BankShared

@MainActor
@Observable
final class UserDetailViewModel {
    var user: User
    var accounts: [Account] = []
    var creditRating: CreditRating?
    var isLoading = false
    var isActionLoading = false
    var errorMessage: String?

    private let userUseCase: UserManagementUseCase
    private let accountUseCase: AccountViewUseCase
    private let ratingUseCase: EmployeeCreditRatingUseCase

    init(user: User, userUseCase: UserManagementUseCase, accountUseCase: AccountViewUseCase, ratingUseCase: EmployeeCreditRatingUseCase) {
        self.user = user
        self.userUseCase = userUseCase
        self.accountUseCase = accountUseCase
        self.ratingUseCase = ratingUseCase
    }

    func load() async {
        isLoading = true
        do {
            async let a = accountUseCase.getAccountsByUser(userId: user.id)
            async let r = ratingUseCase.getCreditRating(userId: user.id)
            accounts = try await a
            creditRating = try? await r
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func toggleBlock() async {
        isActionLoading = true
        errorMessage = nil
        do {
            if user.blocked {
                user = try await userUseCase.unblockUser(id: user.id)
            } else {
                user = try await userUseCase.blockUser(id: user.id)
            }
        } catch {
            errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isActionLoading = false
    }
}
