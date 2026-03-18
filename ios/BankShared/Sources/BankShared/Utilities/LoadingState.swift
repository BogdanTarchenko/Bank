import Foundation

public enum LoadingState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case error(String)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}
