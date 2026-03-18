import Foundation
import BankShared

final class UserUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getUser(id: Int64) async throws -> User {
        try await client.request(UserEndpoint.getById(id))
    }

    func updateUser(id: Int64, request: UpdateUserRequest) async throws -> User {
        try await client.request(UserEndpoint.update(id: id, request))
    }
}
