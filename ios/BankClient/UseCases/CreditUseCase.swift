import Foundation
import BankShared

final class CreditUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getCredits() async throws -> [Credit] {
        try await client.request(CreditEndpoint.getAll)
    }

    func getCredit(id: Int64) async throws -> Credit {
        try await client.request(CreditEndpoint.getById(id))
    }

    func createCredit(request: CreateCreditRequest) async throws -> Credit {
        try await client.request(CreditEndpoint.create(request))
    }

    func getPayments(creditId: Int64) async throws -> [Payment] {
        try await client.request(CreditEndpoint.payments(creditId: creditId))
    }

    func repay(creditId: Int64, amount: Decimal) async throws -> Credit {
        try await client.request(CreditEndpoint.repay(creditId: creditId, RepayRequest(amount: amount)))
    }

    func getTariffs() async throws -> [Tariff] {
        try await client.request(CreditEndpoint.tariffs)
    }

    func getCreditRating(userId: Int64) async throws -> CreditRating {
        try await client.request(CreditEndpoint.creditRating(userId: userId))
    }
}
