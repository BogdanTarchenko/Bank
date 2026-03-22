import { useEffect, useState, useCallback } from 'react'
import {
  Card,
  CardContent,
  Typography,
  Switch,
  FormControlLabel,
  Skeleton,
} from '@mui/material'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { settingsApi } from '@/api/settingsApi'
import { useAuthStore } from '@/store/authStore'
import { useSettingsStore } from '@/store/settingsStore'
import { Theme } from '@/entities/common'
import { ApiError } from '@/network/httpClient'

export function EmployeeSettingsPage() {
  const { enqueueSnackbar } = useSnackbar()
  const user = useAuthStore((s) => s.user)
  const { theme, setTheme } = useSettingsStore()
  const [loading, setLoading] = useState(true)

  const fetchSettings = useCallback(async () => {
    if (!user) return
    try {
      await settingsApi.getSettings(user.userId, 'employee')
    } catch {
    } finally {
      setLoading(false)
    }
  }, [user, setTheme])

  useEffect(() => {
    fetchSettings()
  }, [fetchSettings])

  const handleThemeChange = async (newTheme: Theme) => {
    if (!user) return
    setTheme(newTheme)
    try {
      await settingsApi.updateSettings(user.userId, { theme: newTheme }, 'employee')
      enqueueSnackbar('Тема изменена', { variant: 'success' })
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    }
  }

  if (loading) {
    return (
      <PageLayout title="Настройки">
        <Skeleton variant="rounded" height={150} />
      </PageLayout>
    )
  }

  return (
    <PageLayout title="Настройки">
      <Card>
        <CardContent sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>Внешний вид</Typography>
          <FormControlLabel
            control={
              <Switch
                checked={theme === Theme.DARK}
                onChange={(e) => handleThemeChange(e.target.checked ? Theme.DARK : Theme.LIGHT)}
              />
            }
            label="Тёмная тема"
          />
        </CardContent>
      </Card>
    </PageLayout>
  )
}
