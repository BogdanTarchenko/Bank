import { useEffect, useState, useCallback } from 'react'
import {
  Card,
  CardContent,
  Typography,
  Switch,
  FormControlLabel,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Skeleton,
} from '@mui/material'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { settingsApi } from '@/api/settingsApi'
import { accountApi } from '@/api/accountApi'
import { useAuthStore } from '@/store/authStore'
import { useSettingsStore } from '@/store/settingsStore'
import { Theme } from '@/entities/common'
import { formatMoney } from '@/shared/utils/format'
import type { AccountResponse } from '@/entities/account'
import { ApiError } from '@/network/httpClient'

export function ClientSettingsPage() {
  const { enqueueSnackbar } = useSnackbar()
  const user = useAuthStore((s) => s.user)
  const { theme, setTheme, hiddenAccounts, toggleAccountVisibility, setHiddenAccounts } = useSettingsStore()
  const [accounts, setAccounts] = useState<AccountResponse[]>([])
  const [loading, setLoading] = useState(true)

  const fetchData = useCallback(async () => {
    if (!user) return
    try {
      const [accs, settings] = await Promise.all([
        accountApi.getAccounts(user.userId),
        settingsApi.getSettings(user.userId).catch(() => null),
      ])
      setAccounts(accs.filter((a) => !a.isClosed))
      if (settings) {
        setTheme(settings.theme)
        setHiddenAccounts(settings.hiddenAccounts)
      }
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [user, enqueueSnackbar, setTheme, setHiddenAccounts])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const handleThemeChange = async (newTheme: Theme) => {
    if (!user) return
    setTheme(newTheme)
    try {
      await settingsApi.updateSettings(user.userId, { theme: newTheme })
      enqueueSnackbar('Тема изменена', { variant: 'success' })
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    }
  }

  const handleToggleAccount = async (accountId: number) => {
    if (!user) return
    toggleAccountVisibility(accountId)
    const newHidden = hiddenAccounts.includes(accountId)
      ? hiddenAccounts.filter((id) => id !== accountId)
      : [...hiddenAccounts, accountId]
    try {
      await settingsApi.updateSettings(user.userId, { hiddenAccounts: newHidden })
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    }
  }

  if (loading) {
    return (
      <PageLayout title="Настройки">
        <Skeleton variant="rounded" height={300} />
      </PageLayout>
    )
  }

  return (
    <PageLayout title="Настройки">
      <Card sx={{ mb: 3 }}>
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

      <Card>
        <CardContent sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>Скрытые счета</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Скрытые счета не отображаются на главной странице
          </Typography>
          <Divider />
          <List>
            {accounts.map((account) => (
              <ListItem key={account.id}>
                <ListItemText
                  primary={`Счёт #${account.id}`}
                  secondary={formatMoney(account.balance, account.currency)}
                />
                <ListItemSecondaryAction>
                  <Switch
                    checked={hiddenAccounts.includes(account.id)}
                    onChange={() => handleToggleAccount(account.id)}
                  />
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        </CardContent>
      </Card>
    </PageLayout>
  )
}
