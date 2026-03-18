import SwiftUI
import BankShared

struct EmployeeUserDetailView: View {
    @EnvironmentObject private var container: EmployeeDependencyContainer
    @State private var viewModel: UserDetailViewModel?
    let user: User

    var body: some View {
        Group {
            if let viewModel {
                List {
                    Section {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(viewModel.user.blocked ? .red : .appPrimary)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(viewModel.user.fullName).font(.title2.bold())
                                    if viewModel.user.blocked {
                                        StatusBadge("Заблокирован", color: .red)
                                    }
                                }
                                Text(viewModel.user.email).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("Данные") {
                        LabeledContent("ID", value: "\(viewModel.user.id)")
                        LabeledContent("Телефон", value: viewModel.user.phone ?? "—")
                        LabeledContent("Роли", value: viewModel.user.roles.map(\.rawValue).joined(separator: ", "))
                        LabeledContent("Регистрация", value: viewModel.user.createdAt.toShortDate())
                    }

                    Section("Счета") {
                        if viewModel.accounts.isEmpty {
                            Text("Нет счетов").foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.accounts) { account in
                                HStack {
                                    Text("Счёт #\(account.id)")
                                    CurrencyBadge(account.currency)
                                    Spacer()
                                    Text(account.balance.formatted(currency: account.currency))
                                        .font(.subheadline.monospacedDigit())
                                }
                            }
                        }
                    }

                    if let rating = viewModel.creditRating {
                        Section("Кредитный рейтинг") {
                            LabeledContent("Рейтинг", value: "\(rating.score) — \(rating.grade)")
                            LabeledContent("Активных кредитов", value: "\(rating.activeCredits)")
                            LabeledContent("Просроченных платежей", value: "\(rating.overduePayments)")
                        }
                    }

                    Section {
                        Button(viewModel.user.blocked ? "Разблокировать" : "Заблокировать", role: viewModel.user.blocked ? nil : .destructive) {
                            Task { await viewModel.toggleBlock() }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Section { Text(error).foregroundStyle(.red).font(.caption) }
                    }
                }
                .loadingOverlay(viewModel.isActionLoading)
            } else {
                LoadingView()
            }
        }
        .navigationTitle(user.fullName)
        .task {
            if viewModel == nil {
                viewModel = UserDetailViewModel(
                    user: user,
                    userUseCase: container.userUseCase,
                    accountUseCase: container.accountUseCase,
                    ratingUseCase: container.ratingUseCase
                )
            }
            await viewModel?.load()
        }
    }
}
