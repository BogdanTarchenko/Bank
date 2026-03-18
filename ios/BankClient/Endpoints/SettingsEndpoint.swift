import Foundation
import BankShared

enum SettingsEndpoint: Endpoint {
    case get(userId: Int64)
    case update(userId: Int64, UpdateSettingsRequest)

    var path: String { "/api/v1/settings" }

    var method: HTTPMethod {
        switch self {
        case .get: .GET
        case .update: .PUT
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
        case .get(let userId), .update(let userId, _):
            [URLQueryItem(name: "userId", value: "\(userId)")]
        }
    }
}
