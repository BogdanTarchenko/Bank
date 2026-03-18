import Foundation
import BankShared

struct ClientAuthConfiguration: AuthConfiguration {
    let authBaseURL = "http://localhost:8081"
    let clientId = "client-bff"
    let clientSecret = "client-bff-secret"
    let redirectUri = "bankapp://callback"
    let scopes = "openid profile accounts.read accounts.write credits.read credits.write"
}

enum ClientConfiguration {
    static let bffBaseURL = "http://localhost:8084"
    static let auth = ClientAuthConfiguration()
}
