/**
 * Idempotency key generation.
 * Adds X-Idempotency-Key header to all mutating requests (POST, PUT, PATCH, DELETE).
 * This ensures that retried requests don't cause duplicate side effects.
 */

import type { AxiosInstance, InternalAxiosRequestConfig } from 'axios'

const MUTATING_METHODS = new Set(['post', 'put', 'patch', 'delete'])

export function applyIdempotencyInterceptor(client: AxiosInstance): void {
  client.interceptors.request.use((config: InternalAxiosRequestConfig) => {
    const method = (config.method ?? 'get').toLowerCase()

    if (MUTATING_METHODS.has(method) && !config.headers.get('X-Idempotency-Key')) {
      config.headers.set('X-Idempotency-Key', crypto.randomUUID())
    }

    return config
  })
}
