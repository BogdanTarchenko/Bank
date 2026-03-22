import SwiftUI
import BankShared

@MainActor
@Observable
final class SettingsViewModel {
    var settings: UserSettings?
    var isLoading = false
    var errorMessage: String?

    private let useCase: SettingsUseCase
    private let userId: Int64

    init(useCase: SettingsUseCase, userId: Int64) {
        self.useCase = useCase
        self.userId = userId
    }

    func load() async {
        if settings == nil { isLoading = true }
        do {
            settings = try await useCase.getSettings(userId: userId)
        } catch is CancellationError {
            // Не меняем состояние при отмене
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

    func updateHiddenAccounts(_ hiddenAccounts: Set<Int64>) async {
        do {
            settings = try await useCase.updateSettings(
                userId: userId,
                request: UpdateSettingsRequest(hiddenAccounts: Array(hiddenAccounts))
            )
        } catch {
            errorMessage = error.userMessage
        }
    }
}
