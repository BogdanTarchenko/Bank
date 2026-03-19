import Foundation

public actor HTTPClient {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var tokenProvider: (@Sendable () async -> String?)?
    private var onUnauthorized: (@Sendable () async -> Void)?
    private var onForbidden: (@Sendable () async -> Void)?

    public init(baseURL: String) {
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    public func setTokenProvider(_ provider: @escaping @Sendable () async -> String?) {
        self.tokenProvider = provider
    }

    public func setOnUnauthorized(_ handler: @escaping @Sendable () async -> Void) {
        self.onUnauthorized = handler
    }

    public func setOnForbidden(_ handler: @escaping @Sendable () async -> Void) {
        self.onForbidden = handler
    }

    public func request<T: Decodable & Sendable>(_ endpoint: any Endpoint) async throws -> T {
        let request = try await buildRequest(endpoint)
        let (data, response) = try await performRequest(request)
        try mapError(response: response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }

    public func requestVoid(_ endpoint: any Endpoint) async throws {
        let request = try await buildRequest(endpoint)
        let (data, response) = try await performRequest(request)
        try mapError(response: response, data: data)
    }

    private func buildRequest(_ endpoint: any Endpoint) async throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        if let queryItems = endpoint.queryItems {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await tokenProvider?() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.networkFailure("Invalid response")
            }
            return (data, httpResponse)
        } catch let error as NetworkError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw NetworkError.networkFailure(error.localizedDescription)
        }
    }

    private func mapError(response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            Task { await onUnauthorized?() }
            throw NetworkError.unauthorized
        case 403:
            Task { await onForbidden?() }
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 409:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.conflict(errorResponse.message)
            }
            throw NetworkError.conflict("Conflict")
        case 400...499:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse)
            }
            throw NetworkError.unknown(response.statusCode)
        case 500...599:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse)
            }
            throw NetworkError.unknown(response.statusCode)
        default:
            throw NetworkError.unknown(response.statusCode)
        }
    }
}

private struct AnyEncodable: Encodable, @unchecked Sendable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
