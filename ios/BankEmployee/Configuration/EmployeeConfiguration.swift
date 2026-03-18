import Foundation
import BankShared

struct EmployeeAuthConfiguration: AuthConfiguration {
    let authBaseURL = "http://localhost:8081"
    let clientId = "employee-bff"
    let clientSecret = "employee-bff-secret"
    let redirectUri = "bankemployee://callback"
    let scopes = "openid profile admin"
}

enum EmployeeConfiguration {
    static let bffBaseURL = "http://localhost:8085"
    static let auth = EmployeeAuthConfiguration()
}
