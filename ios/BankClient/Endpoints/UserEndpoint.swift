import Foundation
import BankShared

enum UserEndpoint: Endpoint {
    case getById(Int64)
    case getAll
    case getByEmail(String)
    case update(id: Int64, UpdateUserRequest)
    case block(Int64)
    case unblock(Int64)

    var path: String {
        switch self {
        case .getById(let id): "/api/v1/proxy/user/users/\(id)"
        case .getAll: "/api/v1/proxy/user/users"
        case .getByEmail: "/api/v1/proxy/user/users/by-email"
        case .update(let id, _): "/api/v1/proxy/user/users/\(id)"
        case .block(let id): "/api/v1/proxy/user/users/\(id)/block"
        case .unblock(let id): "/api/v1/proxy/user/users/\(id)/unblock"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getById, .getAll, .getByEmail: .GET
        case .update: .PUT
        case .block, .unblock: .PATCH
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .update(_, let req): req
        default: nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getByEmail(let email): [URLQueryItem(name: "email", value: email)]
        default: nil
        }
    }
}
