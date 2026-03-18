import Foundation
import BankShared

enum EmployeeCreditRatingEndpoint: Endpoint {
    case getByUserId(Int64)

    var path: String {
        switch self {
        case .getByUserId(let id): "/api/v1/proxy/credit/users/\(id)/credit-rating"
        }
    }

    var method: HTTPMethod { .GET }
}
