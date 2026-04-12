import axios from 'axios'
import type { ErrorResponse } from '@/entities/common'
import { useAuthStore } from '@/store/authStore'
import { applyRetryInterceptor } from './retry'
import { applyTracingInterceptor } from './tracing'
import { applyIdempotencyInterceptor } from './idempotency'
import {
  resolveService,
  canRequest,
  recordSuccess,
  recordFailure,
  CircuitBreakerError,
} from './circuitBreaker'

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

// === 1. Idempotency keys (must be first — before retry duplicates the request) ===
applyIdempotencyInterceptor(httpClient)

// === 2. Tracing — adds X-Trace-Id header and measures duration ===
applyTracingInterceptor(httpClient)

// === 3. Auth token injection ===
httpClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token')
  if (token && !config.url?.includes('/oauth2/token')) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// === 4. Circuit Breaker — check before sending ===
httpClient.interceptors.request.use((config) => {
  const service = resolveService(config.url ?? '')
  if (!canRequest(service)) {
    const error = new CircuitBreakerError(service)
    return Promise.reject(error)
  }
  return config
})

// === 5. Response handling — circuit breaker recording + error mapping ===
httpClient.interceptors.response.use(
  (response) => {
    const service = resolveService(response.config.url ?? '')
    recordSuccess(service)
    return response
  },
  (error: unknown) => {
    if (error instanceof CircuitBreakerError) {
      return Promise.reject(
        new ApiError(503, 'CircuitBreakerOpen', error.message, new Date().toISOString()),
      )
    }

    if (axios.isAxiosError(error)) {
      const service = resolveService(error.config?.url ?? '')
      const status = error.response?.status ?? 0

      // Record failure for 5xx and network errors
      if (status >= 500 || status === 0) {
        recordFailure(service)
      } else {
        recordSuccess(service)
      }

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

// === 6. Retry — must be last so it wraps everything above ===
applyRetryInterceptor(httpClient)

export { httpClient }
