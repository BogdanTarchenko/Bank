import { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Card,
  CardContent,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Skeleton,
  Alert,
} from '@mui/material'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { fetchClientAccounts } from '@/usecases/accountUseCases'
import { fetchTariffs, createCredit as createCreditUseCase } from '@/usecases/creditUseCases'
import { formatMoney, getCurrencySymbol } from '@/shared/utils/format'
import { CurrencyLabel } from '@/entities/common'
import type { Currency } from '@/entities/common'
import type { AccountResponse } from '@/entities/account'
import type { TariffResponse } from '@/entities/credit'
import { ApiError } from '@/api'

export function NewCreditPage() {
  const navigate = useNavigate()
  const { enqueueSnackbar } = useSnackbar()
  const [accounts, setAccounts] = useState<AccountResponse[]>([])
  const [tariffs, setTariffs] = useState<TariffResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [accountId, setAccountId] = useState<number | ''>('')
  const [tariffId, setTariffId] = useState<number | ''>('')
  const [amount, setAmount] = useState('')
  const [termDays, setTermDays] = useState('')

  const fetchData = useCallback(async () => {
    try {
      const [accs, tarrs] = await Promise.all([
        fetchClientAccounts(),
        fetchTariffs(),
      ])
      setAccounts(accs.filter((a) => !a.isClosed))
      setTariffs(tarrs.filter((t) => t.active))
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [enqueueSnackbar])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const selectedTariff = tariffs.find((t) => t.id === tariffId)
  const filteredAccounts = selectedTariff
    ? accounts.filter((a) => a.currency === selectedTariff.currency)
    : accounts

  const handleTariffChange = (newTariffId: number) => {
    setTariffId(newTariffId)
    setAccountId('')
  }

  const handleSubmit = async () => {
    if (!accountId || !tariffId || !amount || !termDays) {
      enqueueSnackbar('Заполните все поля', { variant: 'warning' })
      return
    }

    setSubmitting(true)
    try {
      await createCreditUseCase({
        accountId: accountId,
        tariffId: tariffId,
        amount: parseFloat(amount),
        termDays: parseInt(termDays),
      })
      enqueueSnackbar('Кредит успешно оформлен', { variant: 'success' })
      navigate('/client/credits')
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <PageLayout title="Новый кредит">
        <Skeleton variant="rounded" height={400} />
      </PageLayout>
    )
  }

  return (
    <PageLayout
      title="Оформить кредит"
      breadcrumbs={[
        { label: 'Мои кредиты', href: '/client/credits' },
        { label: 'Новый кредит' },
      ]}
    >
      <Card sx={{ maxWidth: 500 }}>
        <CardContent sx={{ p: 3 }}>
          <FormControl fullWidth sx={{ mb: 3 }}>
            <InputLabel>Тариф</InputLabel>
            <Select
              value={tariffId}
              label="Тариф"
              onChange={(e) => handleTariffChange(e.target.value as number)}
            >
              {tariffs.map((t) => (
                <MenuItem key={t.id} value={t.id}>
                  {t.name} — {t.interestRate}% ({CurrencyLabel[t.currency] ?? t.currency})
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          {selectedTariff && (
            <Alert severity="info" sx={{ mb: 2 }}>
              Ставка: {selectedTariff.interestRate}%
              {` • Валюта: ${CurrencyLabel[selectedTariff.currency] ?? selectedTariff.currency}`}
              {selectedTariff.minAmount && ` • от ${selectedTariff.minAmount.toLocaleString('ru-RU')} ${getCurrencySymbol(selectedTariff.currency as Currency)}`}
              {selectedTariff.maxAmount && ` • до ${selectedTariff.maxAmount.toLocaleString('ru-RU')} ${getCurrencySymbol(selectedTariff.currency as Currency)}`}
              {` • от ${selectedTariff.minTermDays} дней`}
              {selectedTariff.maxTermDays && ` до ${selectedTariff.maxTermDays} дней`}
              {filteredAccounts.length === 0 && ` • ⚠ Нет счетов в валюте ${CurrencyLabel[selectedTariff.currency] ?? selectedTariff.currency}`}
            </Alert>
          )}

          <FormControl fullWidth sx={{ mb: 3 }}>
            <InputLabel>Счёт зачисления</InputLabel>
            <Select
              value={accountId}
              label="Счёт зачисления"
              onChange={(e) => setAccountId(e.target.value as number)}
              disabled={filteredAccounts.length === 0}
            >
              {filteredAccounts.map((a) => (
                <MenuItem key={a.id} value={a.id}>
                  Счёт #{a.id} — {formatMoney(a.balance, a.currency)}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <TextField
            label="Сумма кредита"
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            fullWidth
            sx={{ mb: 3 }}
            slotProps={{ htmlInput: { min: 1, step: 1 } }}
          />

          <TextField
            label="Срок (дней)"
            type="number"
            value={termDays}
            onChange={(e) => setTermDays(e.target.value)}
            fullWidth
            sx={{ mb: 3 }}
            slotProps={{ htmlInput: { min: 1, step: 1 } }}
          />

          <LoadingButton
            variant="contained"
            fullWidth
            size="large"
            loading={submitting}
            onClick={handleSubmit}
            disabled={!accountId || !tariffId || !amount || !termDays}
          >
            Оформить кредит
          </LoadingButton>
        </CardContent>
      </Card>
    </PageLayout>
  )
}
