import Foundation
import BankShared

@MainActor
final class DependencyContainer: ObservableObject {
    let httpClient: HTTPClient
    let authManager: AuthManager
    let webSocketManager: WebSocketManager

    // UseCases
    lazy var accountUseCase = AccountUseCase(client: httpClient)
    lazy var transferUseCase = TransferUseCase(client: httpClient)
    lazy var creditUseCase = CreditUseCase(client: httpClient)
    lazy var userUseCase = UserUseCase(client: httpClient)
    lazy var settingsUseCase = SettingsUseCase(client: httpClient)
    lazy var authUseCase = AuthUseCase(authManager: authManager)

    init() {
        let auth = ClientConfiguration.auth
        self.authManager = AuthManager(config: auth)
        self.httpClient = HTTPClient(baseURL: ClientConfiguration.bffBaseURL)
        self.webSocketManager = WebSocketManager()
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
