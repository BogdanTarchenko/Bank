import Foundation
import BankShared

enum CreditEndpoint: Endpoint {
    case create(CreateCreditRequest)
    case getByUserId(Int64)
    case getById(Int64)
    case payments(creditId: Int64)
    case repay(creditId: Int64, RepayRequest)
    case tariffs
    case creditRating(userId: Int64)

    var path: String {
        switch self {
        case .create, .getByUserId: "/api/v1/proxy/credit/credits"
        case .getById(let id): "/api/v1/proxy/credit/credits/\(id)"
        case .payments(let id): "/api/v1/proxy/credit/credits/\(id)/payments"
        case .repay(let id, _): "/api/v1/proxy/credit/credits/\(id)/repay"
        case .tariffs: "/api/v1/proxy/credit/tariffs"
        case .creditRating(let userId): "/api/v1/proxy/credit/users/\(userId)/credit-rating"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create, .repay: .POST
        default: .GET
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .create(let req): req
        case .repay(_, let req): req
        default: nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getByUserId(let userId): [URLQueryItem(name: "userId", value: "\(userId)")]
        default: nil
        }
    }
}
