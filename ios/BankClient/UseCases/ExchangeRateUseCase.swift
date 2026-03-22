import Foundation
import BankShared

final class ExchangeRateUseCase: Sendable {

    private let baseURL = "https://api.exchangerate-api.com/v4/latest"

    func getRates() async throws -> [ExchangeRate] {
        let usdRates = try await fetchRates(base: .USD)
        let eurRates = try await fetchRates(base: .EUR)

        var result: [ExchangeRate] = []
        if let usdToRub = usdRates["RUB"] {
            result.append(ExchangeRate(from: .USD, to: .RUB, rate: usdToRub))
        }
        if let eurToRub = eurRates["RUB"] {
            result.append(ExchangeRate(from: .EUR, to: .RUB, rate: eurToRub))
        }
        if let usdToEur = usdRates["EUR"] {
            result.append(ExchangeRate(from: .USD, to: .EUR, rate: usdToEur))
        }
        return result
    }

    private func fetchRates(base: Currency) async throws -> [String: Double] {
        guard let url = URL(string: "\(baseURL)/\(base.rawValue)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        return decoded.rates
    }
}
