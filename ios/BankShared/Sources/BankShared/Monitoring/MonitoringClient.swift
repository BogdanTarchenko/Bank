import Foundation

public actor MonitoringClient {
    public static let shared = MonitoringClient()
    private let baseURL: String
    private let session: URLSession
    private let encoder: JSONEncoder
    private var serviceName = "ios-client"

    private init() {
        self.baseURL = "http://localhost:8086"
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        self.session = URLSession(configuration: config)
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    public func configure(serviceName: String) {
        self.serviceName = serviceName
    }

    public func record(
        type: MetricType,
        traceId: String?,
        method: String?,
        path: String?,
        statusCode: Int?,
        durationMs: Int64?,
        errorMessage: String? = nil,
        metadata: String? = nil
    ) {
        let payload = MetricPayload(
            type: type.rawValue,
            service: serviceName,
            traceId: traceId,
            durationMs: durationMs,
            method: method,
            path: path,
            statusCode: statusCode,
            errorMessage: errorMessage,
            metadata: metadata
        )
        Task {
            await self.send(payload)
        }
    }

    private func send(_ payload: MetricPayload) async {
        guard let url = URL(string: baseURL + "/api/v1/metrics"),
              let body = try? encoder.encode(payload) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        _ = try? await session.data(for: request)
    }
}

public enum MetricType: String, Sendable {
    case request = "REQUEST"
    case error = "ERROR"
    case circuitBreakerOpen = "CIRCUIT_BREAKER_OPEN"
    case circuitBreakerClose = "CIRCUIT_BREAKER_CLOSE"
    case retry = "RETRY"
}

private struct MetricPayload: Encodable {
    let type: String
    let service: String
    let traceId: String?
    let durationMs: Int64?
    let method: String?
    let path: String?
    let statusCode: Int?
    let errorMessage: String?
    let metadata: String?
}
