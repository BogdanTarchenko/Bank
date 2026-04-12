import { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Button,
  Grid,
  Card,
  CardContent,
  ToggleButton,
  ToggleButtonGroup,
} from '@mui/material'
import DeleteIcon from '@mui/icons-material/Delete'
import RefreshIcon from '@mui/icons-material/Refresh'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
} from 'recharts'
import { useMonitoringStore, type RequestLog } from '@/store/monitoringStore'
import {
  getCircuitStates,
  CircuitState,
} from '@/network/circuitBreaker'

function CircuitStateChip({ state }: { state: CircuitState }) {
  const colorMap: Record<CircuitState, 'success' | 'error' | 'warning'> = {
    [CircuitState.CLOSED]: 'success',
    [CircuitState.OPEN]: 'error',
    [CircuitState.HALF_OPEN]: 'warning',
  }
  return <Chip label={state} color={colorMap[state]} size="small" />
}

function StatusChip({ status, isError }: { status: number; isError: boolean }) {
  if (isError || status >= 500) return <Chip label={status || 'NET'} color="error" size="small" />
  if (status >= 400) return <Chip label={status} color="warning" size="small" />
  return <Chip label={status} color="success" size="small" />
}

type TabValue = 'overview' | 'logs'

export function MonitoringPage() {
  const { clearLogs, getTimeSeries, getServiceStats, getRecentLogs } = useMonitoringStore()
  const [tab, setTab] = useState<TabValue>('overview')
  const [, setTick] = useState(0)

  // Auto-refresh every 2 seconds
  useEffect(() => {
    const id = setInterval(() => setTick((t) => t + 1), 2000)
    return () => clearInterval(id)
  }, [])

  const timeSeries = getTimeSeries()
  const serviceStats = getServiceStats()
  const recentLogs = getRecentLogs(100)
  const circuitStates = getCircuitStates()

  const totalRequests = serviceStats.reduce((s, v) => s + v.totalRequests, 0)
  const totalErrors = serviceStats.reduce((s, v) => s + v.totalErrors, 0)
  const overallErrorRate = totalRequests > 0 ? Math.round((totalErrors / totalRequests) * 100) : 0
  const avgLatency = serviceStats.length > 0
    ? Math.round(serviceStats.reduce((s, v) => s + v.avgLatency, 0) / serviceStats.length)
    : 0

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3, gap: 2 }}>
        <Typography variant="h5" sx={{ flexGrow: 1 }}>
          Мониторинг
        </Typography>
        <ToggleButtonGroup
          value={tab}
          exclusive
          onChange={(_, v) => v && setTab(v)}
          size="small"
        >
          <ToggleButton value="overview">Обзор</ToggleButton>
          <ToggleButton value="logs">Логи</ToggleButton>
        </ToggleButtonGroup>
        <Button
          startIcon={<DeleteIcon />}
          onClick={clearLogs}
          size="small"
          color="error"
          variant="outlined"
        >
          Очистить
        </Button>
      </Box>

      {tab === 'overview' && (
        <>
          {/* Summary cards */}
          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid size={{ xs: 6, md: 3 }}>
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary">Всего запросов</Typography>
                  <Typography variant="h4">{totalRequests}</Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid size={{ xs: 6, md: 3 }}>
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary">Ошибки</Typography>
                  <Typography variant="h4" color="error.main">{totalErrors}</Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid size={{ xs: 6, md: 3 }}>
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary">% ошибок</Typography>
                  <Typography variant="h4" color={overallErrorRate > 50 ? 'error.main' : 'text.primary'}>
                    {overallErrorRate}%
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid size={{ xs: 6, md: 3 }}>
              <Card>
                <CardContent>
                  <Typography variant="body2" color="text.secondary">Ср. латентность</Typography>
                  <Typography variant="h4">{avgLatency} мс</Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>

          {/* Circuit Breaker states */}
          <Paper sx={{ p: 2, mb: 3 }}>
            <Typography variant="h6" gutterBottom>Circuit Breaker</Typography>
            <Grid container spacing={2}>
              {Object.entries(circuitStates).map(([service, info]) => (
                <Grid size={{ xs: 12, sm: 6, md: 4 }} key={service}>
                  <Card variant="outlined">
                    <CardContent>
                      <Typography variant="subtitle2" gutterBottom>{service}</Typography>
                      <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                        <CircuitStateChip state={info.state} />
                        <Typography variant="body2" color="text.secondary">
                          Ошибки: {Math.round(info.errorRate * 100)}% ({info.total} запросов)
                        </Typography>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
              {Object.keys(circuitStates).length === 0 && (
                <Grid size={{ xs: 12 }}>
                  <Typography variant="body2" color="text.secondary">Нет данных</Typography>
                </Grid>
              )}
            </Grid>
          </Paper>

          {/* Time series charts */}
          {timeSeries.length > 0 && (
            <>
              <Paper sx={{ p: 2, mb: 3 }}>
                <Typography variant="h6" gutterBottom>Запросы и ошибки (последние 5 минут)</Typography>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={timeSeries}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="time" fontSize={12} />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Bar dataKey="requests" name="Запросы" fill="#1976d2" />
                    <Bar dataKey="errors" name="Ошибки" fill="#d32f2f" />
                  </BarChart>
                </ResponsiveContainer>
              </Paper>

              <Paper sx={{ p: 2, mb: 3 }}>
                <Typography variant="h6" gutterBottom>Средняя латентность (мс)</Typography>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={timeSeries}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="time" fontSize={12} />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line type="monotone" dataKey="avgLatency" name="Латентность (мс)" stroke="#ff9800" strokeWidth={2} />
                  </LineChart>
                </ResponsiveContainer>
              </Paper>

              <Paper sx={{ p: 2, mb: 3 }}>
                <Typography variant="h6" gutterBottom>Процент ошибок (%)</Typography>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={timeSeries}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="time" fontSize={12} />
                    <YAxis domain={[0, 100]} />
                    <Tooltip />
                    <Legend />
                    <Line type="monotone" dataKey="errorRate" name="% ошибок" stroke="#d32f2f" strokeWidth={2} />
                  </LineChart>
                </ResponsiveContainer>
              </Paper>
            </>
          )}

          {/* Per-service stats table */}
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>Статистика по сервисам</Typography>
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Сервис</TableCell>
                    <TableCell align="right">Запросы</TableCell>
                    <TableCell align="right">Ошибки</TableCell>
                    <TableCell align="right">% ошибок</TableCell>
                    <TableCell align="right">Ср. латентность</TableCell>
                    <TableCell align="right">P95 латентность</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {serviceStats.map((s) => (
                    <TableRow key={s.service}>
                      <TableCell>{s.service}</TableCell>
                      <TableCell align="right">{s.totalRequests}</TableCell>
                      <TableCell align="right">{s.totalErrors}</TableCell>
                      <TableCell align="right">
                        <Chip
                          label={`${s.errorRate}%`}
                          color={s.errorRate > 50 ? 'error' : s.errorRate > 20 ? 'warning' : 'success'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell align="right">{s.avgLatency} мс</TableCell>
                      <TableCell align="right">{s.p95Latency} мс</TableCell>
                    </TableRow>
                  ))}
                  {serviceStats.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={6} align="center">Нет данных</TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </Paper>
        </>
      )}

      {tab === 'logs' && (
        <Paper sx={{ p: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2, gap: 1 }}>
            <Typography variant="h6" sx={{ flexGrow: 1 }}>
              Последние запросы ({recentLogs.length})
            </Typography>
            <Button startIcon={<RefreshIcon />} onClick={() => setTick((t) => t + 1)} size="small">
              Обновить
            </Button>
          </Box>
          <TableContainer sx={{ maxHeight: 600 }}>
            <Table size="small" stickyHeader>
              <TableHead>
                <TableRow>
                  <TableCell>Время</TableCell>
                  <TableCell>Trace ID</TableCell>
                  <TableCell>Сервис</TableCell>
                  <TableCell>Метод</TableCell>
                  <TableCell>URL</TableCell>
                  <TableCell align="right">Статус</TableCell>
                  <TableCell align="right">Время (мс)</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {recentLogs.map((log: RequestLog) => (
                  <TableRow key={log.traceId + log.timestamp}>
                    <TableCell sx={{ whiteSpace: 'nowrap' }}>
                      {new Date(log.timestamp).toLocaleTimeString('ru-RU')}
                    </TableCell>
                    <TableCell sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}>
                      {log.traceId.slice(0, 8)}...
                    </TableCell>
                    <TableCell>{log.service}</TableCell>
                    <TableCell>
                      <Chip label={log.method} size="small" variant="outlined" />
                    </TableCell>
                    <TableCell sx={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {log.url}
                    </TableCell>
                    <TableCell align="right">
                      <StatusChip status={log.status} isError={log.isError} />
                    </TableCell>
                    <TableCell align="right">{log.duration}</TableCell>
                  </TableRow>
                ))}
                {recentLogs.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={7} align="center">Нет данных</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Paper>
      )}
    </Box>
  )
}
