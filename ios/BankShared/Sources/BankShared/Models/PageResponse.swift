import Foundation

public struct PageResponse<T: Codable & Sendable>: Codable, Sendable {
    public let content: [T]
    public let totalElements: Int
    public let totalPages: Int
    public let size: Int
    public let number: Int

    public var hasNext: Bool { number < totalPages - 1 }
}
