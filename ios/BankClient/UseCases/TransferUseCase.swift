import Foundation
import BankShared

final class TransferUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func transfer(from fromAccountId: Int64, to toAccountId: Int64, amount: Decimal) async throws {
        try await client.requestVoid(TransferEndpoint.transfer(
            TransferRequest(fromAccountId: fromAccountId, toAccountId: toAccountId, amount: amount)
        ))
    }
}
