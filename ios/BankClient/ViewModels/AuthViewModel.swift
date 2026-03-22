import SwiftUI
import BankShared

@MainActor
@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var firstName = ""
    var lastName = ""
    var phone = ""
    var isLoading = false
    var errorMessage: String?
    var registrationSuccess = false

    private let useCase: AuthUseCase

    init(useCase: AuthUseCase) {
        self.useCase = useCase
    }

    var isRegisterFormValid: Bool {
        Validator.isValidEmail(email) && Validator.isValidPassword(password)
            && !firstName.isEmpty && !lastName.isEmpty
    }

    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            try await useCase.login()
        } catch {
            errorMessage = error.userMessage
        }
        isLoading = false
    }

    func register() async {
        isLoading = true
        errorMessage = nil
        do {
            try await useCase.register(
                email: email, password: password,
                firstName: firstName, lastName: lastName, phone: phone
            )
            registrationSuccess = true
        } catch {
            errorMessage = error.userMessage
        }
        isLoading = false
    }
}
