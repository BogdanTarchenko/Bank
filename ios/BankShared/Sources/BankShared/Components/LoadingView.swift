import SwiftUI

public struct LoadingView: View {
    let message: String

    public init(_ message: String = "Загрузка...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
