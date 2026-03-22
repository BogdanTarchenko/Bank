/**
 * Use-case: Авторизация и аутентификация
 * Содержит бизнес-логику OAuth2 callback, определения роли, логаута.
 */
import { authApi } from '@/api/authApi'
import { useAuthStore } from '@/store/authStore'
import { Role } from '@/entities/common'
import type { UserInfo } from '@/entities/auth'

/** Определяет портал по ролям пользователя */
export function detectActiveRole(roles: string[]): 'client' | 'employee' {
  if (roles.includes(Role.ADMIN) || roles.includes(Role.EMPLOYEE)) {
    return 'employee'
  }
  return 'client'
}

/** Обрабатывает OAuth2 callback: обмен кода на токены, сохранение авторизации */
export async function handleAuthCallback(
  code: string,
  state: string,
): Promise<{ userInfo: UserInfo; role: 'client' | 'employee' }> {
  const { tokenResponse, userInfo } = await authApi.exchangeCode(code, state)

  localStorage.setItem('access_token', tokenResponse.access_token)
  if (tokenResponse.refresh_token) {
    localStorage.setItem('refresh_token', tokenResponse.refresh_token)
  }

  const { setAuth, setActiveRole } = useAuthStore.getState()
  setAuth(userInfo, tokenResponse.access_token, tokenResponse.refresh_token)

  const role = detectActiveRole(userInfo.roles)
  setActiveRole(role)

  return { userInfo, role }
}

/** Выполняет логаут: очистка состояния + редирект на auth-service */
export function performLogout(): void {
  const { logout } = useAuthStore.getState()
  logout()
  window.location.href = 'http://localhost:8081/logout'
}

export function startLogin(): void {
  authApi.startAuthFlow()
}

export async function registerUser(request: Parameters<typeof authApi.register>[0]): Promise<{ message: string }> {
  return authApi.register(request)
}
