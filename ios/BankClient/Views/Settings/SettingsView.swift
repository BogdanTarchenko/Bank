import SwiftUI
import BankShared

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(AppState.self) private var appState
    @State private var viewModel: SettingsViewModel?

    var body: some View {
        NavigationStack {
            Form {
                Section("Внешний вид") {
                    if let settings = viewModel?.settings {
                        HStack {
                            Text("Тема")
                            Spacer()
                            Text(settings.theme == .LIGHT ? "Светлая" : "Тёмная")
                                .foregroundStyle(.secondary)
                            Button {
                                Task {
                                    await viewModel?.toggleTheme()
                                    if let theme = viewModel?.settings?.theme {
                                        appState.theme = theme
                                    }
                                }
                            } label: {
                                Image(systemName: settings.theme == .LIGHT ? "sun.max" : "moon.fill")
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }

                if let error = viewModel?.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }

                Section {
                    Button("Выйти из аккаунта", role: .destructive) {
                        authManager.logout()
                    }
                }
            }
            .navigationTitle("Настройки")
            .task {
                if viewModel == nil {
                    viewModel = SettingsViewModel(
                        useCase: SettingsUseCase(client: HTTPClient(baseURL: ClientConfiguration.bffBaseURL)),
                        userId: 1
                    )
                }
                await viewModel?.load()
            }
        }
    }
}
