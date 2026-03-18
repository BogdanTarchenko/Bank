import SwiftUI
import BankShared

@MainActor
@Observable
final class TariffListViewModel {
    var state: LoadingState<[Tariff]> = .idle
    var showCreateSheet = false

    // Create form
    var name = ""
    var interestRate = ""
    var minAmount = ""
    var maxAmount = ""
    var minTermDays = ""
    var maxTermDays = ""
    var isCreating = false
    var createError: String?

    private let useCase: TariffManagementUseCase

    init(useCase: TariffManagementUseCase) {
        self.useCase = useCase
    }

    var isCreateFormValid: Bool {
        !name.isEmpty && Validator.isValidAmount(interestRate)
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await useCase.getTariffs())
        } catch {
            state = .error((error as? NetworkError)?.localizedDescription ?? error.localizedDescription)
        }
    }

    func createTariff() async {
        isCreating = true
        createError = nil
        do {
            _ = try await useCase.createTariff(request: CreateTariffRequest(
                name: name,
                interestRate: Decimal(string: interestRate) ?? 0,
                minAmount: Decimal(string: minAmount),
                maxAmount: Decimal(string: maxAmount),
                minTermDays: Int(minTermDays),
                maxTermDays: Int(maxTermDays)
            ))
            showCreateSheet = false
            resetForm()
            await load()
        } catch {
            createError = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
        }
        isCreating = false
    }

    private func resetForm() {
        name = ""
        interestRate = ""
        minAmount = ""
        maxAmount = ""
        minTermDays = ""
        maxTermDays = ""
    }
}
