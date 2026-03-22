import Foundation
import BankShared

enum EmployeeCreditEndpoint: Endpoint {
    case getByUserId(Int64)
    case getById(Int64)
    case payments(creditId: Int64)

    var path: String {
        switch self {
        case .getByUserId: "/api/v1/proxy/credit/credits"
        case .getById(let id): "/api/v1/proxy/credit/credits/\(id)"
        case .payments(let id): "/api/v1/proxy/credit/credits/\(id)/payments"
        }
    }

    var method: HTTPMethod { .GET }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getByUserId(let userId):
            [URLQueryItem(name: "userId", value: "\(userId)")]
        default:
            nil
        }
    }
}
