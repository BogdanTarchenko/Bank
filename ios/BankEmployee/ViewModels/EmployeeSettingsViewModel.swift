import SwiftUI
import BankShared

@MainActor
@Observable
final class EmployeeSettingsViewModel {
    var settings: UserSettings?
    var isLoading = false
    var errorMessage: String?

    private let useCase: EmployeeSettingsUseCase
    private let userId: Int64

    init(useCase: EmployeeSettingsUseCase, userId: Int64) {
        self.useCase = useCase
        self.userId = userId
    }

    func load() async {
        isLoading = true
        do {
            settings = try await useCase.getSettings(userId: userId)
        } catch {
            errorMessage = error.userMessage
        }
        isLoading = false
    }

    func toggleTheme() async {
        guard let current = settings else { return }
        let newTheme: Theme = current.theme == .LIGHT ? .DARK : .LIGHT
        do {
            settings = try await useCase.updateSettings(userId: userId, request: UpdateSettingsRequest(theme: newTheme))
        } catch {
            errorMessage = error.userMessage
        }
    }
}
