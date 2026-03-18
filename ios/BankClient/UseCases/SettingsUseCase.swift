import Foundation
import BankShared

final class SettingsUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getSettings(userId: Int64) async throws -> UserSettings {
        try await client.request(SettingsEndpoint.get(userId: userId))
    }

    func updateSettings(userId: Int64, request: UpdateSettingsRequest) async throws -> UserSettings {
        try await client.request(SettingsEndpoint.update(userId: userId, request))
    }
}
