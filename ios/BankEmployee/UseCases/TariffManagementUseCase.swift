import Foundation
import BankShared

final class TariffManagementUseCase: Sendable {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getTariffs() async throws -> [Tariff] {
        try await client.request(EmployeeTariffEndpoint.getAll)
    }

    func createTariff(request: CreateTariffRequest) async throws -> Tariff {
        try await client.request(EmployeeTariffEndpoint.create(request))
    }
}
