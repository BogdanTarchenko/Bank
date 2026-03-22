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
            let msg = serverMessage(from: data)
            throw NetworkError.forbidden(msg)
        case 404:
            throw NetworkError.notFound(serverMessage(from: data))
        case 400:
            throw NetworkError.badRequest(serverMessage(from: data))
        case 409:
            throw NetworkError.conflict(serverMessage(from: data))
        case 422:
            throw NetworkError.unprocessable(serverMessage(from: data))
        case 400...499:
            throw NetworkError.unknown(response.statusCode, serverMessage(from: data))
        case 500...599:
            let msg = serverMessage(from: data)
            if response.statusCode == 503 {
                throw NetworkError.serviceUnavailable(msg)
            }
            throw NetworkError.serverError(msg)
        default:
            throw NetworkError.unknown(response.statusCode, serverMessage(from: data))
        }
    }

    private func serverMessage(from data: Data) -> String {
        (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? ""
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
