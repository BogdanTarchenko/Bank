import Foundation

public struct UserSettings: Codable, Sendable {
    public let userId: Int64
    public let theme: Theme
    public let hiddenAccounts: [Int64]
}
