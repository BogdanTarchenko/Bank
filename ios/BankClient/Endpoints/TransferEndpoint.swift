import Foundation
import BankShared

enum TransferEndpoint: Endpoint {
    case transfer(TransferRequest)

    var path: String { "/api/v1/transfers" }
    var method: HTTPMethod { .POST }
    var body: (any Encodable & Sendable)? {
        switch self {
        case .transfer(let req): req
        }
    }
}
