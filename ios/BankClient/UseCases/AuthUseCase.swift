import Foundation
import BankShared

@MainActor
final class AuthUseCase {
    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func login() async throws {
        try await authManager.login()
    }

    func register(email: String, password: String, firstName: String, lastName: String, phone: String?) async throws {
        let request = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phone: phone?.isEmpty == true ? nil : phone,
            roles: ["CLIENT"]
        )
        try await authManager.register(request: request)
    }

    func logout() {
        authManager.logout()
    }
}
