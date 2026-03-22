import SwiftUI
import BankShared

@MainActor
@Observable
final class ExchangeRateViewModel {
    var rates: [ExchangeRate] = []
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    private let useCase: ExchangeRateUseCase

    init(useCase: ExchangeRateUseCase) {
        self.useCase = useCase
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            rates = try await useCase.getRates()
            lastUpdated = Date()
        } catch {
            errorMessage = "Не удалось загрузить курсы валют: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
