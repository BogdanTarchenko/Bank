import Foundation

public extension Error {
    var userMessage: String {
        (self as? NetworkError)?.localizedDescription ?? localizedDescription
    }
}

public enum NetworkError: Error, Sendable {
    case unauthorized
    case forbidden(String)
    case notFound(String)
    case badRequest(String)
    case conflict(String)
    case unprocessable(String)
    case serverError(String)
    case serviceUnavailable(String)
    case networkFailure(String)
    case decodingError(String)
    case invalidURL
    case unknown(Int, String)

    public var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "Необходима авторизация"
        case .forbidden(let msg):
            return msg.isEmpty ? "Доступ запрещён" : msg
        case .notFound(let msg):
            return msg.isEmpty ? "Ресурс не найден" : msg
        case .badRequest(let msg):
            return msg
        case .conflict(let msg):
            return msg
        case .unprocessable(let msg):
            return msg
        case .serverError(let msg):
            return msg.isEmpty ? "Внутренняя ошибка сервера" : msg
        case .serviceUnavailable(let msg):
            return msg.isEmpty ? "Сервис временно недоступен" : msg
        case .networkFailure(let msg):
            return "Ошибка сети: \(msg)"
        case .decodingError(let msg):
            return "Ошибка данных: \(msg)"
        case .invalidURL:
            return "Неверный URL"
        case .unknown(let code, let msg):
            return msg.isEmpty ? "Ошибка \(code)" : msg
        }
    }
}
