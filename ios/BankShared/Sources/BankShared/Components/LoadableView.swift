import SwiftUI

public struct LoadableView<T: Sendable, Content: View>: View {
    let state: LoadingState<T>
    let onRetry: (() -> Void)?
    @ViewBuilder let content: (T) -> Content

    public init(state: LoadingState<T>, onRetry: (() -> Void)? = nil, @ViewBuilder content: @escaping (T) -> Content) {
        self.state = state
        self.onRetry = onRetry
        self.content = content
    }

    public var body: some View {
        switch state {
        case .idle, .loading:
            LoadingView()
        case .loaded(let value):
            content(value)
        case .error(let message):
            ErrorView(message, onRetry: onRetry)
        }
    }
}
