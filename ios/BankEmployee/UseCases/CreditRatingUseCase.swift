import Foundation
import BankShared

final class EmployeeCreditRatingUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getCreditRating(userId: Int64) async throws -> CreditRating {
        try await client.request(EmployeeCreditRatingEndpoint.getByUserId(userId))
    }
}
