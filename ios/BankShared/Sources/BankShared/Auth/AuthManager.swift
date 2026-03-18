import Foundation
import AuthenticationServices

@MainActor
public final class AuthManager: ObservableObject {
    private let config: any AuthConfiguration
    private let keychain: KeychainHelper
    private let decoder = JSONDecoder()

    @Published public var accessToken: String?
    @Published public var isAuthenticated = false
    @Published public var userId: Int64?

    public init(config: any AuthConfiguration) {
        self.config = config
        self.keychain = KeychainHelper(service: config.clientId)
        self.accessToken = keychain.get("access_token")
        if let savedId = keychain.get("user_id"), let id = Int64(savedId) {
            self.userId = id
        }
        self.isAuthenticated = accessToken != nil
    }

    public func login() async throws {
        let codeVerifier = PKCEHelper.generateCodeVerifier()
        let codeChallenge = PKCEHelper.generateCodeChallenge(from: codeVerifier)

        var components = URLComponents(string: "\(config.authBaseURL)/oauth2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "scope", value: config.scopes),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        let authURL = components.url!
        let callbackScheme = URL(string: config.redirectUri)!.scheme!

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NetworkError.unauthorized)
                }
            }
            session.presentationContextProvider = ASWebAuthenticationPresentationContextProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NetworkError.unauthorized
        }

        let tokenResponse = try await exchangeCode(code, codeVerifier: codeVerifier)
        saveTokens(tokenResponse)
        try await fetchUserInfo()
    }

    public func register(request: RegisterRequest) async throws {
        guard let url = URL(string: "\(config.authBaseURL)/api/v1/auth/register") else {
            throw NetworkError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure("Invalid response")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse)
            }
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }

    public func fetchUserInfo() async throws {
        guard let token = accessToken,
              let url = URL(string: "\(config.authBaseURL)/userinfo") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else { return }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let sub = json["sub"] as? String, let id = Int64(sub) {
            userId = id
            keychain.save("\(id)", for: "user_id")
        }
    }

    public func logout() {
        keychain.deleteAll()
        accessToken = nil
        userId = nil
        isAuthenticated = false
    }

    public func getAccessToken() -> String? {
        accessToken
    }

    private func exchangeCode(_ code: String, codeVerifier: String) async throws -> TokenResponse {
        guard let url = URL(string: "\(config.authBaseURL)/oauth2/token") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let credentials = "\(config.clientId):\(config.clientSecret)"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

        let body = [
            "grant_type=authorization_code",
            "code=\(code)",
            "redirect_uri=\(config.redirectUri)",
            "code_verifier=\(codeVerifier)"
        ].joined(separator: "&")
        request.httpBody = Data(body.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.unauthorized
        }
        return try decoder.decode(TokenResponse.self, from: data)
    }

    private func saveTokens(_ response: TokenResponse) {
        keychain.save(response.accessToken, for: "access_token")
        if let refresh = response.refreshToken {
            keychain.save(refresh, for: "refresh_token")
        }
        accessToken = response.accessToken
        isAuthenticated = true
    }
}

private final class ASWebAuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = ASWebAuthenticationPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
