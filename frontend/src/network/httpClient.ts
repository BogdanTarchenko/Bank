import axios from 'axios'
import type { ErrorResponse } from '@/entities/common'
import { useAuthStore } from '@/store/authStore'

export class ApiError extends Error {
  status: number
  errorCode: string
  timestamp: string

  constructor(
    status: number,
    errorCode: string,
    message: string,
    timestamp: string,
  ) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.errorCode = errorCode
    this.timestamp = timestamp
  }
}

const httpClient = axios.create({
  headers: {
    'Content-Type': 'application/json',
  },
})

const AUTH_URLS = ['/auth/oauth2/token', '/auth/userinfo', '/auth/api/v1/auth/register']
const BFF_PREFIXES = ['/api/client', '/api/employee']

httpClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token')
  if (token && !config.url?.includes('/oauth2/token')) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

httpClient.interceptors.response.use(
  (response) => response,
  (error: unknown) => {
    if (axios.isAxiosError(error)) {
      const requestUrl = error.config?.url ?? ''
      const isAuthUrl = AUTH_URLS.some((url) => requestUrl.includes(url))

      if (error.response?.status === 401 && !isAuthUrl) {
        useAuthStore.getState().logout()
        window.location.href = '/login'
        return Promise.reject(new ApiError(401, 'Unauthorized', 'Сессия истекла', new Date().toISOString()))
      }

      const isBffUrl = BFF_PREFIXES.some((prefix) => requestUrl.startsWith(prefix))
      if (error.response?.status === 403 && isBffUrl && !isAuthUrl) {
        useAuthStore.getState().logout()
        window.location.href = '/login'
        return Promise.reject(new ApiError(403, 'Forbidden', 'Недостаточно прав. Выполните повторный вход.', new Date().toISOString()))
      }

      const data = error.response?.data as ErrorResponse | undefined
      if (data?.message) {
        return Promise.reject(new ApiError(data.status, data.error, data.message, data.timestamp))
      }

      return Promise.reject(
        new ApiError(
          error.response?.status ?? 500,
          'NetworkError',
          error.message || 'Ошибка сети',
          new Date().toISOString(),
        ),
      )
    }
    return Promise.reject(error)
  },
)

export { httpClient }
