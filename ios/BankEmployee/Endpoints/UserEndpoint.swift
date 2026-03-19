import Foundation
import BankShared

enum EmployeeUserEndpoint: Endpoint {
    case getAll
    case getById(Int64)
    case getByEmail(String)
    case block(Int64)
    case unblock(Int64)

    var path: String {
        switch self {
        case .getAll: "/api/v1/proxy/user/users"
        case .getById(let id): "/api/v1/proxy/user/users/\(id)"
        case .getByEmail: "/api/v1/proxy/user/users/by-email"
        case .block(let id): "/api/v1/proxy/user/users/\(id)/block"
        case .unblock(let id): "/api/v1/proxy/user/users/\(id)/unblock"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getAll, .getById, .getByEmail: .GET
        case .block, .unblock: .PATCH
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getByEmail(let email): [URLQueryItem(name: "email", value: email)]
        default: nil
        }
    }
}
