import Foundation

@MainActor
public final class AuthManager: ObservableObject {
    private let config: any AuthConfiguration
    private let keychain: KeychainHelper
    private let decoder = JSONDecoder()

    @Published public var accessToken: String?
    @Published public var isAuthenticated = false
    @Published public var userId: Int64?
    @Published public var email: String?
    @Published public var showLoginWebView = false
    @Published public var accessDeniedMessage: String?

    /// Callback to resolve email → numeric userId from user-service
    public var userIdResolver: (@Sendable (String) async throws -> Int64)?

    private var codeVerifier: String?
    private var loginContinuation: CheckedContinuation<Void, Error>?
    private var forcePromptLogin = false

    public var authConfig: any AuthConfiguration { config }

    public init(config: any AuthConfiguration) {
        self.config = config
        self.keychain = KeychainHelper(service: config.clientId)
        self.accessToken = keychain.get("access_token")
        if let savedId = keychain.get("user_id"), let id = Int64(savedId) {
            self.userId = id
        }
        if let savedEmail = keychain.get("email") {
            self.email = savedEmail
        }
        self.isAuthenticated = accessToken != nil
    }

    public func login() async throws {
        let verifier = PKCEHelper.generateCodeVerifier()
        self.codeVerifier = verifier

        // Если был 403, при повторном входе принудительно показываем форму логина
        if accessDeniedMessage != nil {
            forcePromptLogin = true
            accessDeniedMessage = nil
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.loginContinuation = continuation
            self.showLoginWebView = true
        }
    }

    public func buildAuthURL() -> URL? {
        guard let verifier = codeVerifier else { return nil }
        let challenge = PKCEHelper.generateCodeChallenge(from: verifier)

        var components = URLComponents(string: "\(config.authBaseURL)/oauth2/authorize")!
        var queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "scope", value: config.scopes),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        // Принудительно показать форму логина (после 403 — чтобы войти другим аккаунтом)
        if forcePromptLogin {
            queryItems.append(URLQueryItem(name: "prompt", value: "login"))
            forcePromptLogin = false
        }

        components.queryItems = queryItems
        return components.url
    }

    public func handleCallback(url: URL) async {
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value,
              let verifier = codeVerifier else {
            loginContinuation?.resume(throwing: NetworkError.unauthorized)
            loginContinuation = nil
            showLoginWebView = false
            return
        }

        do {
            let tokenResponse = try await exchangeCode(code, codeVerifier: verifier)
            saveTokens(tokenResponse)
            try await fetchUserInfo()
            showLoginWebView = false
            loginContinuation?.resume()
            loginContinuation = nil
        } catch {
            showLoginWebView = false
            loginContinuation?.resume(throwing: error)
            loginContinuation = nil
        }
        codeVerifier = nil
    }

    public func cancelLogin() {
        showLoginWebView = false
        loginContinuation?.resume(throwing: NetworkError.unauthorized)
        loginContinuation = nil
        codeVerifier = nil
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
           let sub = json["sub"] as? String {
            // sub is email, not numeric ID
            email = sub
            keychain.save(sub, for: "email")

            // Try numeric ID first (fallback)
            if let id = Int64(sub) {
                userId = id
                keychain.save("\(id)", for: "user_id")
            } else if let resolver = userIdResolver {
                // Resolve email → numeric userId via user-service
                let id = try await resolver(sub)
                userId = id
                keychain.save("\(id)", for: "user_id")
            }
        }
    }

    /// Resolve userId from email if not yet resolved (e.g., after app restart)
    public func resolveUserIdIfNeeded() async {
        guard userId == nil, let email, let resolver = userIdResolver else { return }
        do {
            let id = try await resolver(email)
            userId = id
            keychain.save("\(id)", for: "user_id")
        } catch {
            // userId resolution failed, will retry on next app launch
        }
    }

    public func logout() {
        keychain.deleteAll()
        accessToken = nil
        userId = nil
        email = nil
        isAuthenticated = false
        accessDeniedMessage = nil
    }

    /// Вызывается при 403 Forbidden — разлогинивает и сохраняет сообщение об ошибке
    public func denyAccess(message: String = "Доступ запрещён. Войдите с другим аккаунтом.") {
        keychain.deleteAll()
        accessToken = nil
        userId = nil
        email = nil
        isAuthenticated = false
        accessDeniedMessage = message
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
