import SwiftUI

public struct OperationRow: View {
    let operation: Operation

    public init(operation: Operation) {
        self.operation = operation
    }

    public var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundStyle(operation.type.isIncoming ? .green : .red)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(operation.type.displayName)
                    .font(.subheadline.bold())
                if let desc = operation.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(operation.createdAt.toDisplayDate())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text("\(operation.type.isIncoming ? "+" : "-")\(operation.amount.formattedPlain())")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(operation.type.isIncoming ? .green : .red)
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch operation.type {
        case .DEPOSIT: "arrow.down.circle.fill"
        case .WITHDRAWAL: "arrow.up.circle.fill"
        case .TRANSFER_IN: "arrow.down.left.circle.fill"
        case .TRANSFER_OUT: "arrow.up.right.circle.fill"
        }
    }
}
