import SwiftUI
import BankShared

struct SettingsView: View {
    @EnvironmentObject private var container: DependencyContainer
    @EnvironmentObject private var authManager: AuthManager
    @Environment(AppState.self) private var appState
    @State private var viewModel: SettingsViewModel?
    @State private var accounts: [Account] = []

    var body: some View {
        NavigationStack {
            Form {
                themeSection
                accountVisibilitySection
                errorSection
                logoutSection
            }
            .navigationTitle("Настройки")
            .task(id: appState.currentUserId) {
                guard let userId = appState.currentUserId else { return }
                if viewModel == nil {
                    viewModel = SettingsViewModel(
                        useCase: container.settingsUseCase,
                        userId: userId
                    )
                }
                await viewModel?.load()
                if let settings = viewModel?.settings {
                    appState.applySettings(settings)
                }
                do {
                    let allAccounts = try await container.accountUseCase.getAccounts(userId: userId)
                    accounts = allAccounts.filter { !$0.isClosed && $0.accountType == .PERSONAL }
                } catch {
                    // Секция видимости счетов не покажется
                }
            }
        }
    }

    @ViewBuilder
    private var themeSection: some View {
        Section("Внешний вид") {
            if let settings = viewModel?.settings {
                ThemeRow(theme: settings.theme) {
                    Task {
                        await viewModel?.toggleTheme()
                        if let theme = viewModel?.settings?.theme {
                            appState.theme = theme
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private var accountVisibilitySection: some View {
        if !accounts.isEmpty {
            Section {
                ForEach(accounts) { account in
                    AccountVisibilityRow(
                        account: account,
                        isHidden: appState.isHidden(accountId: account.id)
                    ) {
                        appState.toggleHidden(accountId: account.id)
                        Task {
                            await viewModel?.updateHiddenAccounts(appState.hiddenAccounts)
                        }
                    }
                }
            } header: {
                Text("Видимость счетов")
            } footer: {
                Text("Скрытые счета не отображаются в списке. Вы можете показать их кнопкой на экране счетов.")
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel?.errorMessage {
            Section {
                Text(error).foregroundStyle(.red).font(.caption)
            }
        }
    }

    private var logoutSection: some View {
        Section {
            Button("Выйти из аккаунта", role: .destructive) {
                authManager.logout()
            }
        }
    }
}

private struct ThemeRow: View {
    let theme: Theme
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Text("Тема")
            Spacer()
            Text(theme == .LIGHT ? "Светлая" : "Тёмная")
                .foregroundStyle(.secondary)
            Button(action: onToggle) {
                Image(systemName: theme == .LIGHT ? "sun.max" : "moon.fill")
            }
        }
    }
}

private struct AccountVisibilityRow: View {
    let account: Account
    let isHidden: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Счёт #\(account.id)")
                    .font(.subheadline)
                Text(account.balance.formatted(currency: account.currency))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onToggle) {
                Image(systemName: isHidden ? "eye.slash" : "eye")
                    .foregroundStyle(isHidden ? .secondary : .primary)
            }
        }
    }
}
