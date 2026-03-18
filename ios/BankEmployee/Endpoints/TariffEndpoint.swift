import Foundation
import BankShared

enum EmployeeTariffEndpoint: Endpoint {
    case getAll
    case create(CreateTariffRequest)

    var path: String { "/api/v1/proxy/credit/tariffs" }

    var method: HTTPMethod {
        switch self {
        case .getAll: .GET
        case .create: .POST
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .create(let req): req
        default: nil
        }
    }
}
