/**
 * Use-case: Управление пользователями (employee-портал)
 * Содержит бизнес-логику загрузки профиля, блокировки, ролей.
 */
import { userApi } from '@/api/userApi'
import { accountApi } from '@/api/accountApi'
import { creditApi } from '@/api/creditApi'
import type { UserResponse } from '@/entities/user'
import type { AccountResponse } from '@/entities/account'
import type { CreditRatingResponse } from '@/entities/credit'

/** Полный профиль пользователя для employee-портала */
export interface UserProfile {
  user: UserResponse
  accounts: AccountResponse[]
  rating: CreditRatingResponse | null
  availableRoles: string[]
}

/** Загружает полный профиль пользователя со счетами, рейтингом и доступными ролями */
export async function fetchUserProfile(userId: number): Promise<UserProfile> {
  const [user, accounts, rating, availableRoles] = await Promise.all([
    userApi.getUser(userId, 'employee'),
    accountApi.getAccounts(userId, 'employee'),
    creditApi.getCreditRating(userId, 'employee').catch(() => null),
    userApi.getAvailableRoles().catch(() => []),
  ])
  return { user, accounts, rating, availableRoles }
}

/** Обновляет роли пользователя */
export async function updateUserRoles(userId: number, roles: string[]): Promise<UserResponse> {
  return userApi.updateUserRoles(userId, roles)
}

/** Переключает блокировку пользователя */
export async function toggleUserBlock(userId: number, currentlyBlocked: boolean): Promise<UserResponse> {
  return currentlyBlocked
    ? userApi.unblockUser(userId)
    : userApi.blockUser(userId)
}

/** Загружает список пользователей */
export async function fetchUsers(): Promise<UserResponse[]> {
  return userApi.getUsers('employee')
}

export async function fetchUserById(userId: number): Promise<UserResponse> {
  return userApi.getUser(userId, 'employee')
}
