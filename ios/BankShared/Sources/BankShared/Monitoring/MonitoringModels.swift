import Foundation

public struct ServiceStats: Decodable, Identifiable, Sendable {
    public var id: String { service }
    public let service: String
    public let totalRequests: Int
    public let errorCount: Int
    public let errorRate: Double
    public let avgDurationMs: Double
    public let p95DurationMs: Double
}

public struct MetricEventDTO: Decodable, Identifiable, Sendable {
    public let id: Int
    public let type: String
    public let service: String
    public let traceId: String?
    public let method: String?
    public let path: String?
    public let statusCode: Int?
    public let durationMs: Int64?
    public let errorMessage: String?
    public let recordedAt: String?
}
