import SwiftUI
import BankShared

struct EmployeeMonitoringView: View {
    @State private var viewModel = EmployeeMonitoringViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.stats.isEmpty {
                    LoadingView()
                } else {
                    content
                }
            }
            .navigationTitle("Мониторинг")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await viewModel.load() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        List {
            timeWindowSection
            if !viewModel.stats.isEmpty {
                statsSection
            }
            circuitBreakerSection
            if !viewModel.recentErrors.isEmpty {
                errorsSection
            }
        }
        .refreshable { await viewModel.load() }
    }

    private var timeWindowSection: some View {
        Section("Временное окно") {
            Picker("Период", selection: $viewModel.selectedHours) {
                Text("1 час").tag(1)
                Text("6 часов").tag(6)
                Text("24 часа").tag(24)
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedHours) { _, _ in
                Task { await viewModel.load() }
            }
        }
    }

    private var statsSection: some View {
        Section("Статистика сервисов") {
            ForEach(viewModel.stats) { stat in
                ServiceStatRow(stat: stat)
            }
        }
    }

    private var circuitBreakerSection: some View {
        Section("Circuit Breaker") {
            if viewModel.stats.isEmpty {
                Text("Нет данных")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.stats) { stat in
                    HStack {
                        Text(stat.service)
                            .font(.subheadline)
                        Spacer()
                        let isOpen = stat.errorRate > 70
                        Label(
                            isOpen ? "Открыт" : "Закрыт",
                            systemImage: isOpen ? "xmark.circle.fill" : "checkmark.circle.fill"
                        )
                        .foregroundStyle(isOpen ? .red : .green)
                        .font(.caption)
                    }
                }
            }
        }
    }

    private var errorsSection: some View {
        Section("Последние ошибки") {
            ForEach(viewModel.recentErrors) { event in
                ErrorEventRow(event: event)
            }
        }
    }
}

private struct ServiceStatRow: View {
    let stat: ServiceStats

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stat.service)
                .font(.headline)

            HStack(spacing: 16) {
                statItem("Запросов", value: "\(stat.totalRequests)")
                statItem("Ошибок", value: "\(stat.errorCount)")
                statItem("% ошибок", value: String(format: "%.1f%%", stat.errorRate), color: errorRateColor(stat.errorRate))
            }

            HStack(spacing: 16) {
                statItem("Avg", value: String(format: "%.0f ms", stat.avgDurationMs))
                statItem("P95", value: String(format: "%.0f ms", stat.p95DurationMs))
            }
        }
        .padding(.vertical, 4)
    }

    private func statItem(_ label: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    private func errorRateColor(_ rate: Double) -> Color {
        if rate > 70 { return .red }
        if rate > 30 { return .orange }
        return .green
    }
}

private struct ErrorEventRow: View {
    let event: MetricEventDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.service)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let code = event.statusCode {
                    Text("\(code)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
            }
            HStack {
                if let method = event.method {
                    Text(method)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                }
                if let path = event.path {
                    Text(path)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
            if let msg = event.errorMessage, !msg.isEmpty {
                Text(msg)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
            if let durationMs = event.durationMs {
                Text("\(durationMs) ms")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
