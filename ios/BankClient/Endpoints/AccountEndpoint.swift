import Foundation
import BankShared

enum AccountEndpoint: Endpoint {
    case create(CreateAccountRequest)
    case getByUserId(Int64)
    case getById(Int64)
    case close(Int64)
    case deposit(accountId: Int64, MoneyOperationRequest)
    case withdraw(accountId: Int64, MoneyOperationRequest)
    case operations(accountId: Int64, page: Int, size: Int)
    case masterAccounts

    var path: String {
        switch self {
        case .create, .getByUserId: "/api/v1/proxy/core/accounts"
        case .getById(let id): "/api/v1/proxy/core/accounts/\(id)"
        case .close(let id): "/api/v1/proxy/core/accounts/\(id)"
        case .deposit(let id, _): "/api/v1/proxy/core/accounts/\(id)/deposit"
        case .withdraw(let id, _): "/api/v1/proxy/core/accounts/\(id)/withdraw"
        case .operations(let id, _, _): "/api/v1/proxy/core/accounts/\(id)/operations"
        case .masterAccounts: "/api/v1/proxy/core/master-account"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create, .deposit, .withdraw: .POST
        case .getByUserId, .getById, .operations, .masterAccounts: .GET
        case .close: .DELETE
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .create(let req): req
        case .deposit(_, let req): req
        case .withdraw(_, let req): req
        default: nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getByUserId(let userId): [URLQueryItem(name: "userId", value: "\(userId)")]
        case .operations(_, let page, let size): [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        default: nil
        }
    }
}
