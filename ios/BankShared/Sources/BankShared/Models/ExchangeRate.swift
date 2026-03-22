import Foundation

public struct ExchangeRateResponse: Decodable, Sendable {
    public let base: String
    public let rates: [String: Double]
}

public struct ExchangeRate: Identifiable, Sendable {
    public var id: String { "\(from.rawValue)_\(to.rawValue)" }
    public let from: Currency
    public let to: Currency
    public let rate: Double

    public init(from: Currency, to: Currency, rate: Double) {
        self.from = from
        self.to = to
        self.rate = rate
    }
}
