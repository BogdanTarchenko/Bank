import Foundation
import BankShared

final class AccountUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getAccounts(userId: Int64) async throws -> [Account] {
        try await client.request(AccountEndpoint.getByUserId(userId))
    }

    func getAccount(id: Int64) async throws -> Account {
        try await client.request(AccountEndpoint.getById(id))
    }

    func createAccount(userId: Int64, currency: Currency) async throws -> Account {
        try await client.request(AccountEndpoint.create(CreateAccountRequest(userId: userId, currency: currency)))
    }

    func closeAccount(id: Int64) async throws {
        try await client.requestVoid(AccountEndpoint.close(id))
    }

    func deposit(accountId: Int64, amount: Decimal) async throws {
        try await client.requestVoid(AccountEndpoint.deposit(accountId: accountId, MoneyOperationRequest(amount: amount)))
    }

    func withdraw(accountId: Int64, amount: Decimal) async throws {
        try await client.requestVoid(AccountEndpoint.withdraw(accountId: accountId, MoneyOperationRequest(amount: amount)))
    }

    func getOperations(accountId: Int64, page: Int = 0, size: Int = 20) async throws -> PageResponse<Operation> {
        try await client.request(AccountEndpoint.operations(accountId: accountId, page: page, size: size))
    }
}
