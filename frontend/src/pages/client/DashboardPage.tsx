import { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Card,
  CardContent,
  CardActionArea,
  Typography,
  Grid,
  Skeleton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material'
import AddIcon from '@mui/icons-material/Add'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { MoneyDisplay } from '@/shared/ui/MoneyDisplay'
import { EmptyState } from '@/shared/ui/EmptyState'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { accountApi } from '@/api/accountApi'
import { useSettingsStore } from '@/store/settingsStore'
import { Currency, CurrencyLabel } from '@/entities/common'
import type { AccountResponse } from '@/entities/account'
import { ApiError } from '@/network/httpClient'

export function ClientDashboardPage() {
  const navigate = useNavigate()
  const { enqueueSnackbar } = useSnackbar()
  const { hiddenAccounts } = useSettingsStore()
  const [accounts, setAccounts] = useState<AccountResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [openDialog, setOpenDialog] = useState(false)
  const [newCurrency, setNewCurrency] = useState<Currency>(Currency.RUB)
  const [creating, setCreating] = useState(false)

  const fetchAccounts = useCallback(async () => {
    try {
      const data = await accountApi.getAccounts()
      setAccounts(data)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [enqueueSnackbar])

  useEffect(() => {
    fetchAccounts()
  }, [fetchAccounts])

  const handleCreateAccount = async () => {
    setCreating(true)
    try {
      await accountApi.createAccount({ currency: newCurrency })
      enqueueSnackbar('Счёт успешно создан', { variant: 'success' })
      setOpenDialog(false)
      await fetchAccounts()
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setCreating(false)
    }
  }

  const visibleAccounts = accounts.filter(
    (a) => !a.isClosed && !hiddenAccounts.includes(a.id),
  )

  return (
    <PageLayout
      title="Мои счета"
      action={
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenDialog(true)}>
          Открыть счёт
        </Button>
      }
    >
      {loading ? (
        <Grid container spacing={3}>
          {[1, 2, 3].map((i) => (
            <Grid size={{ xs: 12, sm: 6, md: 4 }} key={i}>
              <Skeleton variant="rounded" height={140} />
            </Grid>
          ))}
        </Grid>
      ) : visibleAccounts.length === 0 ? (
        <EmptyState
          title="У вас пока нет счетов"
          description="Откройте свой первый банковский счёт"
          action={
            <Button variant="contained" onClick={() => setOpenDialog(true)}>
              Открыть счёт
            </Button>
          }
        />
      ) : (
        <Grid container spacing={3}>
          {visibleAccounts.map((account) => (
            <Grid size={{ xs: 12, sm: 6, md: 4 }} key={account.id}>
              <Card elevation={2}>
                <CardActionArea onClick={() => navigate(`/client/accounts/${account.id}`)}>
                  <CardContent sx={{ p: 3 }}>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Счёт #{account.id}
                    </Typography>
                    <MoneyDisplay
                      amount={account.balance}
                      currency={account.currency}
                      variant="h5"
                      sx={{ mb: 1 }}
                    />
                    <Typography
                      variant="caption"
                      sx={{
                        px: 1,
                        py: 0.5,
                        borderRadius: 1,
                        bgcolor: 'primary.main',
                        color: 'primary.contrastText',
                      }}
                    >
                      {account.currency}
                    </Typography>
                  </CardContent>
                </CardActionArea>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Открыть новый счёт</DialogTitle>
        <DialogContent>
          <FormControl fullWidth sx={{ mt: 1 }}>
            <InputLabel>Валюта</InputLabel>
            <Select
              value={newCurrency}
              label="Валюта"
              onChange={(e) => setNewCurrency(e.target.value as Currency)}
            >
              {Object.values(Currency).map((c) => (
                <MenuItem key={c} value={c}>{CurrencyLabel[c] ?? c} ({c})</MenuItem>
              ))}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Отмена</Button>
          <LoadingButton variant="contained" loading={creating} onClick={handleCreateAccount}>
            Создать
          </LoadingButton>
        </DialogActions>
      </Dialog>
    </PageLayout>
  )
}
