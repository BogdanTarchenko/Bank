import Foundation
import BankShared

final class EmployeeSettingsUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getSettings(userId: Int64) async throws -> UserSettings {
        try await client.request(EmployeeSettingsEndpoint.get(userId: userId))
    }

    func updateSettings(userId: Int64, request: UpdateSettingsRequest) async throws -> UserSettings {
        try await client.request(EmployeeSettingsEndpoint.update(userId: userId, request))
    }
}
