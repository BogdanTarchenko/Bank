import Foundation

public protocol AuthConfiguration: Sendable {
    var authBaseURL: String { get }
    var clientId: String { get }
    var clientSecret: String { get }
    var redirectUri: String { get }
    var scopes: String { get }
}
