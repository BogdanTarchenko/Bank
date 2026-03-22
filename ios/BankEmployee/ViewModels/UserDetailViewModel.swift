import SwiftUI
import BankShared

@MainActor
@Observable
final class UserDetailViewModel {
    var user: User
    var accounts: [Account] = []
    var credits: [Credit] = []
    var creditRating: CreditRating?
    var isLoading = false
    var isActionLoading = false
    var errorMessage: String?

    private let userUseCase: UserManagementUseCase
    private let accountUseCase: AccountViewUseCase
    private let creditUseCase: EmployeeCreditUseCase
    private let ratingUseCase: EmployeeCreditRatingUseCase

    init(
        user: User,
        userUseCase: UserManagementUseCase,
        accountUseCase: AccountViewUseCase,
        creditUseCase: EmployeeCreditUseCase,
        ratingUseCase: EmployeeCreditRatingUseCase
    ) {
        self.user = user
        self.userUseCase = userUseCase
        self.accountUseCase = accountUseCase
        self.creditUseCase = creditUseCase
        self.ratingUseCase = ratingUseCase
    }

    func load() async {
        isLoading = true
        async let a = accountUseCase.getAccountsByUser(userId: user.id)
        async let c = creditUseCase.getCredits(userId: user.id)
        async let r = ratingUseCase.getCreditRating(userId: user.id)
        do {
            accounts = try await a
        } catch {
            errorMessage = error.userMessage
        }
        do {
            credits = try await c
        } catch {
            credits = []
        }
        creditRating = try? await r
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
            errorMessage = error.userMessage
        }
        isActionLoading = false
    }

    func toggleRole(_ role: UserRole) async {
        isActionLoading = true
        errorMessage = nil
        var newRoles = user.roles
        if newRoles.contains(role) {
            newRoles.remove(role)
        } else {
            newRoles.insert(role)
        }
        do {
            user = try await userUseCase.updateRoles(id: user.id, roles: newRoles)
        } catch {
            errorMessage = error.userMessage
        }
        isActionLoading = false
    }
}
