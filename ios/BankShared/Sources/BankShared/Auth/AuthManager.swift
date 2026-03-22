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
        print("[AUTH] init: isAuthenticated=\(isAuthenticated), userId=\(userId as Any), email=\(email as Any), hasToken=\(accessToken != nil)")
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
            print("[AUTH] handleCallback: exchanging code...")
            let tokenResponse = try await exchangeCode(code, codeVerifier: verifier)
            saveTokens(tokenResponse)
            print("[AUTH] handleCallback: tokens saved, isAuthenticated=\(isAuthenticated)")
            // fetchUserInfo не должен блокировать логин — userId можно получить позже
            do {
                try await fetchUserInfo()
                print("[AUTH] handleCallback: fetchUserInfo done, userId=\(userId as Any), email=\(email as Any)")
            } catch {
                print("[AUTH] handleCallback: fetchUserInfo error: \(error)")
                // Не критично: userId будет получен через resolveUserIdIfNeeded
            }
            showLoginWebView = false
            loginContinuation?.resume()
            loginContinuation = nil
        } catch {
            print("[AUTH] handleCallback: exchangeCode error: \(error)")
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
              let url = URL(string: "\(config.authBaseURL)/userinfo") else {
            print("[AUTH] fetchUserInfo: no token or invalid URL")
            return
        }
        print("[AUTH] fetchUserInfo: calling \(url)")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return }
        print("[AUTH] fetchUserInfo: status=\(httpResponse.statusCode)")
        if httpResponse.statusCode == 401 {
            // Токен невалиден (например, auth-service перегенерировал ключи) — разлогиниваем
            print("[AUTH] fetchUserInfo: 401 → logout")
            logout()
            return
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print("[AUTH] fetchUserInfo: non-200 status, body=\(String(data: data, encoding: .utf8) ?? "nil")")
            return
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let sub = json["sub"] as? String {
            print("[AUTH] fetchUserInfo: sub=\(sub)")
            // sub is email, not numeric ID
            email = sub
            keychain.save(sub, for: "email")

            // Try numeric ID first (fallback)
            if let id = Int64(sub) {
                userId = id
                keychain.save("\(id)", for: "user_id")
                print("[AUTH] fetchUserInfo: numeric userId=\(id)")
            } else if let resolver = userIdResolver {
                print("[AUTH] fetchUserInfo: resolving userId for email=\(sub)...")
                // Resolve email → numeric userId via user-service
                do {
                    let id = try await resolver(sub)
                    userId = id
                    keychain.save("\(id)", for: "user_id")
                    print("[AUTH] fetchUserInfo: resolved userId=\(id)")
                } catch {
                    print("[AUTH] fetchUserInfo: resolver error: \(error)")
                    throw error
                }
            } else {
                print("[AUTH] fetchUserInfo: no resolver set, userId stays nil")
            }
        } else {
            print("[AUTH] fetchUserInfo: failed to parse JSON, body=\(String(data: data, encoding: .utf8) ?? "nil")")
        }
    }

    /// Resolve userId from email if not yet resolved (e.g., after app restart)
    public func resolveUserIdIfNeeded() async {
        print("[AUTH] resolveUserIdIfNeeded: userId=\(userId as Any), email=\(email as Any), isAuthenticated=\(isAuthenticated)")
        guard userId == nil else {
            print("[AUTH] resolveUserIdIfNeeded: userId already set, skip")
            return
        }

        // Если нет email — получим через /userinfo
        if email == nil {
            print("[AUTH] resolveUserIdIfNeeded: no email, calling fetchUserInfo...")
            try? await fetchUserInfo()
            // fetchUserInfo мог уже установить userId через resolver
            if userId != nil {
                print("[AUTH] resolveUserIdIfNeeded: userId set after fetchUserInfo: \(userId!)")
                return
            }
        }

        guard let email, let resolver = userIdResolver else {
            print("[AUTH] resolveUserIdIfNeeded: no email or no resolver, giving up")
            return
        }
        do {
            print("[AUTH] resolveUserIdIfNeeded: resolving userId for \(email)...")
            let id = try await resolver(email)
            userId = id
            keychain.save("\(id)", for: "user_id")
            print("[AUTH] resolveUserIdIfNeeded: resolved userId=\(id)")
        } catch {
            print("[AUTH] resolveUserIdIfNeeded: resolver error: \(error)")
            // userId resolution failed, will retry later
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
