import Foundation
import BankShared

@MainActor
@Observable
final class MonitoringViewModel {
    var stats: [ServiceStats] = []
    var recentErrors: [MetricEventDTO] = []
    var isLoading = false
    var selectedHours = 1

    private let baseURL = "http://localhost:8086"
    private let session = URLSession.shared
    private let decoder = JSONDecoder()

    func load() async {
        isLoading = true
        async let statsResult = fetchStats()
        async let errorsResult = fetchErrors()
        self.stats = (try? await statsResult) ?? []
        self.recentErrors = (try? await errorsResult) ?? []
        isLoading = false
    }

    private func fetchStats() async throws -> [ServiceStats] {
        guard let url = URL(string: "\(baseURL)/api/v1/metrics/stats?hours=\(selectedHours)") else { return [] }
        let (data, _) = try await session.data(from: url)
        return try decoder.decode([ServiceStats].self, from: data)
    }

    private func fetchErrors() async throws -> [MetricEventDTO] {
        guard let url = URL(string: "\(baseURL)/api/v1/metrics/errors?hours=\(selectedHours)&limit=50") else { return [] }
        let (data, _) = try await session.data(from: url)
        return try decoder.decode([MetricEventDTO].self, from: data)
    }
}
