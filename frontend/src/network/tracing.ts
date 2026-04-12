/**
 * Request tracing — generates unique trace IDs and measures request duration.
 * Sends metrics to the monitoring store.
 */

import type { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse, AxiosError } from 'axios'
import { useMonitoringStore, type RequestLog } from '@/store/monitoringStore'
import { resolveService } from './circuitBreaker'

interface TracedConfig extends InternalAxiosRequestConfig {
  metadata?: {
    traceId: string
    startTime: number
  }
}

function generateTraceId(): string {
  return crypto.randomUUID()
}

export function applyTracingInterceptor(client: AxiosInstance): void {
  // Request interceptor — stamp each request with traceId + start time
  client.interceptors.request.use((config: TracedConfig) => {
    const traceId = generateTraceId()
    config.metadata = {
      traceId,
      startTime: performance.now(),
    }
    config.headers.set('X-Trace-Id', traceId)
    return config
  })

  // Response interceptor — record success metrics
  client.interceptors.response.use(
    (response: AxiosResponse) => {
      recordMetric(response.config as TracedConfig, response.status, false)
      return response
    },
    (error: AxiosError) => {
      recordMetric(error.config as TracedConfig | undefined, error.response?.status ?? 0, true)
      return Promise.reject(error)
    },
  )
}

function recordMetric(config: TracedConfig | undefined, status: number, isError: boolean): void {
  if (!config?.metadata) return

  const { traceId, startTime } = config.metadata
  const duration = Math.round(performance.now() - startTime)
  const service = resolveService(config.url ?? '')

  const log: RequestLog = {
    traceId,
    service,
    method: (config.method ?? 'GET').toUpperCase(),
    url: config.url ?? '',
    status,
    duration,
    isError,
    timestamp: Date.now(),
  }

  useMonitoringStore.getState().addLog(log)
}
