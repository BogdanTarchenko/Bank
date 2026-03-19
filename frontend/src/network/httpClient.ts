import axios from 'axios'
import type { ErrorResponse } from '@/entities/common'

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

httpClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

httpClient.interceptors.response.use(
  (response) => response,
  (error: unknown) => {
    if (axios.isAxiosError(error)) {
      if (error.response?.status === 401) {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        window.location.href = '/login'
        return Promise.reject(new ApiError(401, 'Unauthorized', 'Сессия истекла', new Date().toISOString()))
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
