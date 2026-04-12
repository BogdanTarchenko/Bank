/**
 * Retry logic with exponential backoff for axios.
 *
 * Retries on 5xx errors and network failures.
 * Does NOT retry on 4xx (client errors) or auth errors.
 */

import type { AxiosInstance, AxiosError, InternalAxiosRequestConfig } from 'axios'

export interface RetryConfig {
  /** Maximum number of retry attempts */
  maxRetries: number
  /** Base delay in ms (doubles on each attempt) */
  baseDelay: number
  /** Maximum delay cap in ms */
  maxDelay: number
}

const DEFAULT_RETRY: RetryConfig = {
  maxRetries: 3,
  baseDelay: 500,
  maxDelay: 5000,
}

interface AxiosRequestConfigWithRetry extends InternalAxiosRequestConfig {
  __retryCount?: number
  __retryConfig?: RetryConfig
}

function isRetryable(error: AxiosError): boolean {
  // Network error (no response)
  if (!error.response) return true
  // 5xx server errors
  return error.response.status >= 500
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

export function applyRetryInterceptor(
  client: AxiosInstance,
  config: Partial<RetryConfig> = {},
): void {
  const retryConfig: RetryConfig = { ...DEFAULT_RETRY, ...config }

  client.interceptors.response.use(undefined, async (error: AxiosError) => {
    const cfg = error.config as AxiosRequestConfigWithRetry | undefined
    if (!cfg) return Promise.reject(error)

    if (!isRetryable(error)) return Promise.reject(error)

    const rc = cfg.__retryConfig ?? retryConfig
    const count = cfg.__retryCount ?? 0

    if (count >= rc.maxRetries) return Promise.reject(error)

    cfg.__retryCount = count + 1
    cfg.__retryConfig = rc

    const backoff = Math.min(rc.baseDelay * Math.pow(2, count), rc.maxDelay)
    // Add jitter +-25 %
    const jitter = backoff * (0.75 + Math.random() * 0.5)

    console.info(
      `[Retry] Attempt ${cfg.__retryCount}/${rc.maxRetries} for ${cfg.method?.toUpperCase()} ${cfg.url} after ${Math.round(jitter)}ms`,
    )

    await delay(jitter)

    return client.request(cfg)
  })
}
