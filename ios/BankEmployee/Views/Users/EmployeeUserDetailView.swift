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
                    userInfoSection(viewModel)
                    rolesSection(viewModel)
                    accountsSection(viewModel)
                    creditsSection(viewModel)
                    ratingSection(viewModel)
                    actionsSection(viewModel)

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
        .task(id: user.id) {
            if viewModel == nil {
                viewModel = UserDetailViewModel(
                    user: user,
                    userUseCase: container.userUseCase,
                    accountUseCase: container.accountUseCase,
                    creditUseCase: container.creditUseCase,
                    ratingUseCase: container.ratingUseCase
                )
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func userInfoSection(_ vm: UserDetailViewModel) -> some View {
        Section {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(vm.user.blocked ? .red : .appPrimary)
                VStack(alignment: .leading) {
                    HStack {
                        Text(vm.user.fullName).font(.title2.bold())
                        if vm.user.blocked {
                            StatusBadge("Заблокирован", color: .red)
                        }
                    }
                    Text(vm.user.email).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }

        Section("Данные") {
            LabeledContent("ID", value: "\(vm.user.id)")
            LabeledContent("Телефон", value: vm.user.phone ?? "—")
            LabeledContent("Регистрация", value: vm.user.createdAt.toShortDate())
        }
    }

    @ViewBuilder
    private func rolesSection(_ vm: UserDetailViewModel) -> some View {
        Section("Роли") {
            ForEach(UserRole.allCases, id: \.self) { role in
                let hasRole = vm.user.roles.contains(role)
                Button {
                    Task { await vm.toggleRole(role) }
                } label: {
                    HStack {
                        Image(systemName: hasRole ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(hasRole ? Color.appPrimary : .secondary)
                        Text(role.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                .disabled(vm.isActionLoading)
            }
        }
    }

    @ViewBuilder
    private func accountsSection(_ vm: UserDetailViewModel) -> some View {
        Section("Счета (\(vm.accounts.count))") {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if vm.accounts.isEmpty {
                Text("Нет счетов").foregroundStyle(.secondary)
            } else {
                ForEach(vm.accounts) { account in
                    NavigationLink {
                        EmployeeAccountDetailView(account: account)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Счёт #\(account.id)").font(.subheadline.bold())
                                    CurrencyBadge(account.currency)
                                    if account.isClosed {
                                        StatusBadge("Закрыт", color: .secondary)
                                    }
                                }
                                Text(account.accountType.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(account.balance.formatted(currency: account.currency))
                                .font(.subheadline.monospacedDigit())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func creditsSection(_ vm: UserDetailViewModel) -> some View {
        Section("Кредиты (\(vm.credits.count))") {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if vm.credits.isEmpty {
                Text("Нет кредитов").foregroundStyle(.secondary)
            } else {
                ForEach(vm.credits) { credit in
                    NavigationLink {
                        EmployeeCreditDetailView(credit: credit)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(credit.tariffName).font(.subheadline.bold())
                                Text("Остаток: \(credit.remaining.formattedPlain())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusBadge(creditStatus: credit.status)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ratingSection(_ vm: UserDetailViewModel) -> some View {
        if let rating = vm.creditRating {
            Section("Кредитный рейтинг") {
                LabeledContent("Рейтинг") {
                    HStack(spacing: 6) {
                        Text("\(rating.score)").font(.headline)
                        StatusBadge(CreditGrade.displayName(rating.grade), color: CreditGrade.color(rating.grade))
                    }
                }
                LabeledContent("Всего кредитов", value: "\(rating.totalCredits)")
                LabeledContent("Активных кредитов", value: "\(rating.activeCredits)")
                LabeledContent("Просроченных платежей", value: "\(rating.overduePayments)")
                LabeledContent("Всего платежей", value: "\(rating.totalPayments)")
            }
        }
    }

    @ViewBuilder
    private func actionsSection(_ vm: UserDetailViewModel) -> some View {
        Section {
            Button(
                vm.user.blocked ? "Разблокировать" : "Заблокировать",
                role: vm.user.blocked ? nil : .destructive
            ) {
                Task { await vm.toggleBlock() }
            }
            .disabled(vm.isActionLoading)
        }
    }
}
