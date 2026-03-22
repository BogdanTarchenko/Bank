import Foundation
import BankShared

final class EmployeeCreditUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getCredits(userId: Int64) async throws -> [Credit] {
        try await client.request(EmployeeCreditEndpoint.getByUserId(userId))
    }

    func getCredit(id: Int64) async throws -> Credit {
        try await client.request(EmployeeCreditEndpoint.getById(id))
    }

    func getPayments(creditId: Int64) async throws -> [Payment] {
        try await client.request(EmployeeCreditEndpoint.payments(creditId: creditId))
    }
}
