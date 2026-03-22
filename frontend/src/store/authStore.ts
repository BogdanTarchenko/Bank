import { create } from 'zustand'
import type { UserInfo } from '@/entities/auth'
import type { Role } from '@/entities/common'

function loadUser(): UserInfo | null {
  try {
    const raw = localStorage.getItem('user_info')
    if (raw) {
      return JSON.parse(raw) as UserInfo
    }
  } catch {
    // ignore
  }
  return null
}

interface AuthState {
  isAuthenticated: boolean
  user: UserInfo | null
  activeRole: 'client' | 'employee'
  setAuth: (user: UserInfo, accessToken: string, refreshToken: string) => void
  logout: () => void
  setActiveRole: (role: 'client' | 'employee') => void
  hasRole: (role: Role) => boolean
}

export const useAuthStore = create<AuthState>((set, get) => ({
  isAuthenticated: !!localStorage.getItem('access_token'),
  user: loadUser(),
  activeRole: (localStorage.getItem('active_role') as 'client' | 'employee') || 'client',

  setAuth: (user, accessToken, refreshToken) => {
    localStorage.setItem('access_token', accessToken)
    localStorage.setItem('refresh_token', refreshToken)
    localStorage.setItem('user_info', JSON.stringify(user))
    set({ isAuthenticated: true, user })
  },

  logout: () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('active_role')
    localStorage.removeItem('user_info')
    set({ isAuthenticated: false, user: null, activeRole: 'client' })
  },

  setActiveRole: (role) => {
    localStorage.setItem('active_role', role)
    set({ activeRole: role })
  },

  hasRole: (role) => {
    const { user } = get()
    const roles = user?.roles ?? []
    return roles.includes(role)
  },
}))
