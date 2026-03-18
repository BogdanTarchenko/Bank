import Foundation
import BankShared

@MainActor
final class EmployeeDependencyContainer: ObservableObject {
    let httpClient: HTTPClient
    let authManager: AuthManager

    lazy var userUseCase = UserManagementUseCase(client: httpClient)
    lazy var accountUseCase = AccountViewUseCase(client: httpClient)
    lazy var tariffUseCase = TariffManagementUseCase(client: httpClient)
    lazy var ratingUseCase = EmployeeCreditRatingUseCase(client: httpClient)
    lazy var settingsUseCase = EmployeeSettingsUseCase(client: httpClient)

    init() {
        let auth = EmployeeConfiguration.auth
        self.authManager = AuthManager(config: auth)
        self.httpClient = HTTPClient(baseURL: EmployeeConfiguration.bffBaseURL)
    }

    func setup() async {
        await httpClient.setTokenProvider { [weak self] in
            await self?.authManager.getAccessToken()
        }
        await httpClient.setOnUnauthorized { [weak self] in
            await self?.authManager.logout()
        }
    }
}
