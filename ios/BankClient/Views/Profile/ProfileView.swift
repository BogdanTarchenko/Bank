import SwiftUI
import BankShared

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LoadableView(state: viewModel.state, onRetry: { Task { await viewModel.load() } }) { user in
                        List {
                            Section {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.appPrimary)
                                    VStack(alignment: .leading) {
                                        Text(user.fullName).font(.title2.bold())
                                        Text(user.email).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                            }

                            Section("Данные") {
                                LabeledContent("Телефон", value: user.phone ?? "—")
                                LabeledContent("Роль", value: user.roles.map(\.rawValue).joined(separator: ", "))
                                LabeledContent("Регистрация", value: user.createdAt.toShortDate())
                            }

                            if let rating = viewModel.creditRating {
                                Section("Кредитный рейтинг") {
                                    NavigationLink {
                                        CreditRatingView(rating: rating)
                                    } label: {
                                        HStack {
                                            Text("Рейтинг: \(rating.score)")
                                                .font(.headline)
                                            Spacer()
                                            Text(rating.grade)
                                                .font(.title2.bold())
                                                .foregroundStyle(gradeColor(rating.grade))
                                        }
                                    }
                                }
                            }

                            Section {
                                Button("Выйти", role: .destructive) {
                                    authManager.logout()
                                }
                            }
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            .navigationTitle("Профиль")
            .task {
                if viewModel == nil {
                    let client = HTTPClient(baseURL: ClientConfiguration.bffBaseURL)
                    viewModel = ProfileViewModel(
                        userUseCase: UserUseCase(client: client),
                        creditUseCase: CreditUseCase(client: client),
                        userId: 1
                    )
                }
                await viewModel?.load()
            }
        }
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A", "A+": .green
        case "B", "B+": .blue
        case "C": .orange
        default: .red
        }
    }
}
