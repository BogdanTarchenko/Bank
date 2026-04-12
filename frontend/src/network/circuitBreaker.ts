/**
 * Circuit Breaker pattern implementation.
 *
 * States:
 *  - CLOSED  — requests pass through normally
 *  - OPEN    — requests are immediately rejected (error rate > threshold)
 *  - HALF_OPEN — a single probe request is allowed to test recovery
 *
 * Tracks error rate per service prefix over a sliding window.
 * If error rate exceeds 70 %, the circuit opens for `openDuration` ms.
 */

export const CircuitState = {
  CLOSED: 'CLOSED',
  OPEN: 'OPEN',
  HALF_OPEN: 'HALF_OPEN',
} as const
export type CircuitState = (typeof CircuitState)[keyof typeof CircuitState]

interface CircuitEntry {
  state: CircuitState
  failures: number
  successes: number
  total: number
  lastFailureTime: number
  openedAt: number
}

export interface CircuitBreakerOptions {
  /** Sliding-window size (number of recent requests to consider) */
  windowSize: number
  /** Error-rate threshold (0..1). Default 0.7 (70 %) */
  errorThreshold: number
  /** How long the circuit stays open before moving to half-open, ms */
  openDuration: number
  /** Minimum number of requests in window before the breaker can trip */
  minRequests: number
}

const DEFAULT_OPTIONS: CircuitBreakerOptions = {
  windowSize: 20,
  errorThreshold: 0.7,
  openDuration: 10_000,
  minRequests: 5,
}

const circuits = new Map<string, CircuitEntry>()

let options: CircuitBreakerOptions = { ...DEFAULT_OPTIONS }

export function configureCircuitBreaker(opts: Partial<CircuitBreakerOptions>): void {
  options = { ...DEFAULT_OPTIONS, ...opts }
}

function getOrCreate(service: string): CircuitEntry {
  let entry = circuits.get(service)
  if (!entry) {
    entry = {
      state: CircuitState.CLOSED,
      failures: 0,
      successes: 0,
      total: 0,
      lastFailureTime: 0,
      openedAt: 0,
    }
    circuits.set(service, entry)
  }
  return entry
}

/** Resolves a URL to its logical service name (for per-service tracking). */
export function resolveService(url: string): string {
  if (url.startsWith('/api/client')) return 'client-bff'
  if (url.startsWith('/api/employee')) return 'employee-bff'
  if (url.startsWith('/auth')) return 'auth-service'
  return 'unknown'
}

/**
 * Check whether a request to `service` is allowed.
 * Throws if circuit is OPEN and cooldown has not elapsed.
 */
export function canRequest(service: string): boolean {
  const entry = getOrCreate(service)

  if (entry.state === CircuitState.CLOSED) return true

  if (entry.state === CircuitState.OPEN) {
    const elapsed = Date.now() - entry.openedAt
    if (elapsed >= options.openDuration) {
      entry.state = CircuitState.HALF_OPEN
      return true
    }
    return false
  }

  // HALF_OPEN — allow one probe
  return true
}

/** Record a successful response */
export function recordSuccess(service: string): void {
  const entry = getOrCreate(service)

  if (entry.state === CircuitState.HALF_OPEN) {
    // Probe succeeded — close the circuit
    entry.state = CircuitState.CLOSED
    entry.failures = 0
    entry.successes = 0
    entry.total = 0
    return
  }

  entry.successes++
  entry.total++
  trimWindow(entry)
}

/** Record a failed response (5xx or network error) */
export function recordFailure(service: string): void {
  const entry = getOrCreate(service)
  entry.failures++
  entry.total++
  entry.lastFailureTime = Date.now()

  if (entry.state === CircuitState.HALF_OPEN) {
    // Probe failed — reopen circuit
    entry.state = CircuitState.OPEN
    entry.openedAt = Date.now()
    return
  }

  trimWindow(entry)

  if (entry.total >= options.minRequests) {
    const errorRate = entry.failures / entry.total
    if (errorRate >= options.errorThreshold) {
      entry.state = CircuitState.OPEN
      entry.openedAt = Date.now()
    }
  }
}

function trimWindow(entry: CircuitEntry): void {
  if (entry.total > options.windowSize) {
    const excess = entry.total - options.windowSize
    // Approximate trim — reduce proportionally
    const failRatio = entry.failures / entry.total
    entry.failures = Math.max(0, Math.round(entry.failures - excess * failRatio))
    entry.successes = Math.max(0, Math.round(entry.successes - excess * (1 - failRatio)))
    entry.total = entry.failures + entry.successes
  }
}

/** Get current state for monitoring UI */
export function getCircuitStates(): Record<string, { state: CircuitState; errorRate: number; total: number }> {
  const result: Record<string, { state: CircuitState; errorRate: number; total: number }> = {}
  circuits.forEach((entry, service) => {
    result[service] = {
      state: entry.state,
      errorRate: entry.total > 0 ? entry.failures / entry.total : 0,
      total: entry.total,
    }
  })
  return result
}

/** Reset all circuits (for testing) */
export function resetCircuits(): void {
  circuits.clear()
}

export class CircuitBreakerError extends Error {
  service: string
  constructor(service: string) {
    super(`Circuit breaker OPEN for service "${service}". Requests temporarily disabled.`)
    this.name = 'CircuitBreakerError'
    this.service = service
  }
}
