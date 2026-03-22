import { useEffect, useState, useCallback } from 'react'
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
} from '@mui/material'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { fetchClientAccounts } from '@/usecases/accountUseCases'
import { executeTransfer } from '@/usecases/transferUseCases'
import { formatMoney } from '@/shared/utils/format'
import type { AccountResponse } from '@/entities/account'
import { ApiError } from '@/api'

export function TransferPage() {
  const { enqueueSnackbar } = useSnackbar()
  const [accounts, setAccounts] = useState<AccountResponse[]>([])
  const [fromAccountId, setFromAccountId] = useState<number | ''>('')
  const [toAccountId, setToAccountId] = useState<string>('')
  const [amount, setAmount] = useState('')
  const [loading, setLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  const fetchAccounts = useCallback(async () => {
    setLoading(true)
    try {
      const data = await fetchClientAccounts()
      setAccounts(data.filter((a) => !a.isClosed))
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

  const handleTransfer = async () => {
    if (!fromAccountId || !toAccountId || !amount) {
      enqueueSnackbar('Заполните все поля', { variant: 'warning' })
      return
    }

    const parsedAmount = parseFloat(amount)
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      enqueueSnackbar('Введите корректную сумму', { variant: 'warning' })
      return
    }

    const toId = parseInt(toAccountId)
    if (isNaN(toId)) {
      enqueueSnackbar('Введите корректный номер счёта', { variant: 'warning' })
      return
    }

    setSubmitting(true)
    try {
      await executeTransfer({
        fromAccountId: fromAccountId,
        toAccountId: toId,
        amount: parsedAmount,
      })
      enqueueSnackbar('Перевод отправлен', { variant: 'success' })
      setAmount('')
      setToAccountId('')
      await fetchAccounts()
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setSubmitting(false)
    }
  }

  const selectedAccount = accounts.find((a) => a.id === fromAccountId)

  return (
    <PageLayout title="Перевод средств">
      <Card sx={{ maxWidth: 500 }}>
        <CardContent sx={{ p: 3 }}>
          <FormControl fullWidth sx={{ mb: 3 }}>
            <InputLabel>Со счёта</InputLabel>
            <Select
              value={fromAccountId}
              label="Со счёта"
              onChange={(e) => setFromAccountId(e.target.value as number)}
              disabled={loading}
            >
              {accounts.map((a) => (
                <MenuItem key={a.id} value={a.id}>
                  Счёт #{a.id} — {formatMoney(a.balance, a.currency)}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          {selectedAccount && (
            <Alert severity="info" sx={{ mb: 2 }}>
              Доступно: {formatMoney(selectedAccount.balance, selectedAccount.currency)}
            </Alert>
          )}

          <TextField
            label="На счёт (номер)"
            value={toAccountId}
            onChange={(e) => setToAccountId(e.target.value)}
            fullWidth
            sx={{ mb: 3 }}
            placeholder="Введите номер счёта получателя"
          />

          <TextField
            label="Сумма"
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            fullWidth
            sx={{ mb: 3 }}
            slotProps={{ htmlInput: { min: 0.01, step: 0.01 } }}
          />

          <Box>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              При переводе между счетами в разных валютах конвертация происходит автоматически по текущему курсу.
            </Typography>
          </Box>

          <LoadingButton
            variant="contained"
            fullWidth
            size="large"
            loading={submitting}
            onClick={handleTransfer}
            disabled={!fromAccountId || !toAccountId || !amount}
          >
            Перевести
          </LoadingButton>
        </CardContent>
      </Card>
    </PageLayout>
  )
}
