import Foundation

public struct UpdateSettingsRequest: Codable, Sendable {
    public let theme: Theme?
    public let hiddenAccounts: [Int64]?

    public init(theme: Theme? = nil, hiddenAccounts: [Int64]? = nil) {
        self.theme = theme
        self.hiddenAccounts = hiddenAccounts
    }
}
