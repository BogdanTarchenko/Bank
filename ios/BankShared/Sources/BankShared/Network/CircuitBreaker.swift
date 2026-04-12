import Foundation

/// Circuit Breaker per service (keyed by host).
/// States: closed → open → half-open → closed/open
public actor CircuitBreaker {
    public static let shared = CircuitBreaker()

    private struct Breaker {
        var state: State = .closed
        var recentResults: [RequestResult] = []
        var openedAt: Date?
        var halfOpenTestInFlight = false

        enum State { case closed, open, halfOpen }

        struct RequestResult {
            let isError: Bool
            let recordedAt: Date
        }
    }

    private var breakers: [String: Breaker] = [:]
    private let windowSeconds: Double = 60
    private let minRequests = 5
    private let errorThreshold = 0.70
    private let openDurationSeconds: Double = 30

    private init() {}

    /// Returns false if the circuit is open and request should be blocked.
    public func canRequest(service: String) -> Bool {
        var b = breaker(for: service)
        switch b.state {
        case .closed:
            return true
        case .open:
            if let openedAt = b.openedAt,
               Date().timeIntervalSince(openedAt) >= openDurationSeconds {
                b.state = .halfOpen
                b.halfOpenTestInFlight = false
                breakers[service] = b
                return true // allow one test request
            }
            return false
        case .halfOpen:
            if b.halfOpenTestInFlight {
                return false // only one test at a time
            }
            b.halfOpenTestInFlight = true
            breakers[service] = b
            return true
        }
    }

    /// Record the outcome of a request.
    public func record(service: String, isError: Bool) {
        var b = breaker(for: service)
        let now = Date()
        // Prune old results outside the window
        b.recentResults = b.recentResults.filter {
            now.timeIntervalSince($0.recordedAt) <= windowSeconds
        }
        b.recentResults.append(.init(isError: isError, recordedAt: now))

        switch b.state {
        case .closed:
            if b.recentResults.count >= minRequests {
                let errors = b.recentResults.filter { $0.isError }.count
                let rate = Double(errors) / Double(b.recentResults.count)
                if rate > errorThreshold {
                    b.state = .open
                    b.openedAt = now
                    b.halfOpenTestInFlight = false
                    Task { await MonitoringClient.shared.record(type: .circuitBreakerOpen, traceId: nil, method: nil, path: service, statusCode: nil, durationMs: nil, metadata: "error_rate=\(Int(rate * 100))%") }
                }
            }
        case .halfOpen:
            if isError {
                b.state = .open
                b.openedAt = now
                b.halfOpenTestInFlight = false
                Task { await MonitoringClient.shared.record(type: .circuitBreakerOpen, traceId: nil, method: nil, path: service, statusCode: nil, durationMs: nil, metadata: "half-open probe failed") }
            } else {
                b.state = .closed
                b.recentResults = []
                b.halfOpenTestInFlight = false
                Task { await MonitoringClient.shared.record(type: .circuitBreakerClose, traceId: nil, method: nil, path: service, statusCode: nil, durationMs: nil) }
            }
        case .open:
            break
        }

        breakers[service] = b
    }

    private func breaker(for service: String) -> Breaker {
        breakers[service] ?? Breaker()
    }
}
