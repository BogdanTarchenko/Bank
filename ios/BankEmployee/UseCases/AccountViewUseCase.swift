import Foundation
import BankShared

final class AccountViewUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getAllAccounts() async throws -> [Account] {
        try await client.request(EmployeeAccountEndpoint.getAll)
    }

    func getAccount(id: Int64) async throws -> Account {
        try await client.request(EmployeeAccountEndpoint.getById(id))
    }

    func getAccountsByUser(userId: Int64) async throws -> [Account] {
        try await client.request(EmployeeAccountEndpoint.getByUserId(userId))
    }

    func getOperations(accountId: Int64, page: Int = 0, size: Int = 20) async throws -> PageResponse<BankShared.Operation> {
        try await client.request(EmployeeAccountEndpoint.operations(accountId: accountId, page: page, size: size))
    }
}
