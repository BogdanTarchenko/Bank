/**
 * Monitoring store — collects request logs, error rates, latency metrics.
 * Used by the monitoring dashboard and by tracing/circuit breaker modules.
 */

import { create } from 'zustand'

export interface RequestLog {
  traceId: string
  service: string
  method: string
  url: string
  status: number
  duration: number
  isError: boolean
  timestamp: number
}

export interface TimeSeriesPoint {
  time: string
  requests: number
  errors: number
  avgLatency: number
  errorRate: number
}

export interface ServiceStats {
  service: string
  totalRequests: number
  totalErrors: number
  errorRate: number
  avgLatency: number
  p95Latency: number
}

const MAX_LOGS = 1000

interface MonitoringState {
  logs: RequestLog[]
  addLog: (log: RequestLog) => void
  clearLogs: () => void
  getTimeSeries: (intervalMs?: number) => TimeSeriesPoint[]
  getServiceStats: () => ServiceStats[]
  getRecentLogs: (limit?: number) => RequestLog[]
}

export const useMonitoringStore = create<MonitoringState>((set, get) => ({
  logs: [],

  addLog: (log) => {
    set((state) => {
      const logs = [...state.logs, log]
      // Keep only last MAX_LOGS entries
      if (logs.length > MAX_LOGS) {
        return { logs: logs.slice(logs.length - MAX_LOGS) }
      }
      return { logs }
    })
  },

  clearLogs: () => set({ logs: [] }),

  getTimeSeries: (intervalMs = 10_000) => {
    const { logs } = get()
    if (logs.length === 0) return []

    const now = Date.now()
    const windowStart = now - 5 * 60_000 // last 5 minutes
    const recentLogs = logs.filter((l) => l.timestamp >= windowStart)

    const buckets = new Map<number, RequestLog[]>()

    for (const log of recentLogs) {
      const bucket = Math.floor(log.timestamp / intervalMs) * intervalMs
      const existing = buckets.get(bucket)
      if (existing) {
        existing.push(log)
      } else {
        buckets.set(bucket, [log])
      }
    }

    const sorted = Array.from(buckets.entries()).sort(([a], [b]) => a - b)

    return sorted.map(([ts, entries]) => {
      const errors = entries.filter((e) => e.isError).length
      const totalLatency = entries.reduce((sum, e) => sum + e.duration, 0)
      return {
        time: new Date(ts).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
        requests: entries.length,
        errors,
        avgLatency: Math.round(totalLatency / entries.length),
        errorRate: Math.round((errors / entries.length) * 100),
      }
    })
  },

  getServiceStats: () => {
    const { logs } = get()
    const byService = new Map<string, RequestLog[]>()

    for (const log of logs) {
      const existing = byService.get(log.service)
      if (existing) {
        existing.push(log)
      } else {
        byService.set(log.service, [log])
      }
    }

    return Array.from(byService.entries()).map(([service, entries]) => {
      const errors = entries.filter((e) => e.isError).length
      const latencies = entries.map((e) => e.duration).sort((a, b) => a - b)
      const avgLatency = Math.round(latencies.reduce((s, v) => s + v, 0) / latencies.length)
      const p95Index = Math.floor(latencies.length * 0.95)
      const p95Latency = latencies[p95Index] ?? avgLatency

      return {
        service,
        totalRequests: entries.length,
        totalErrors: errors,
        errorRate: Math.round((errors / entries.length) * 100),
        avgLatency,
        p95Latency,
      }
    })
  },

  getRecentLogs: (limit = 50) => {
    const { logs } = get()
    return logs.slice(-limit).reverse()
  },
}))
