import Foundation
import BankShared

enum EmployeeAccountEndpoint: Endpoint {
    case getAll
    case getById(Int64)
    case getByUserId(Int64)
    case operations(accountId: Int64, page: Int, size: Int)

    var path: String {
        switch self {
        case .getAll, .getByUserId: "/api/v1/proxy/core/accounts"
        case .getById(let id): "/api/v1/proxy/core/accounts/\(id)"
        case .operations(let id, _, _): "/api/v1/proxy/core/accounts/\(id)/operations"
        }
    }

    var method: HTTPMethod { .GET }

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
