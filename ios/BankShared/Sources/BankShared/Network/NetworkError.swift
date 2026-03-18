import Foundation

public enum NetworkError: Error, Sendable {
    case unauthorized
    case forbidden
    case notFound
    case conflict(String)
    case serverError(ErrorResponse)
    case networkFailure(String)
    case decodingError(String)
    case invalidURL
    case unknown(Int)

    public var localizedDescription: String {
        switch self {
        case .unauthorized: "Необходима авторизация"
        case .forbidden: "Доступ запрещён"
        case .notFound: "Ресурс не найден"
        case .conflict(let msg): msg
        case .serverError(let err): err.message
        case .networkFailure(let msg): "Ошибка сети: \(msg)"
        case .decodingError(let msg): "Ошибка данных: \(msg)"
        case .invalidURL: "Неверный URL"
        case .unknown(let code): "Ошибка: \(code)"
        }
    }
}
