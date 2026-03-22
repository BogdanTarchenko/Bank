import { useEffect, useState, useCallback } from 'react'
import { useParams } from 'react-router-dom'
import {
  Card,
  CardContent,
  Typography,
  Grid,
  Skeleton,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
} from '@mui/material'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { MoneyDisplay } from '@/shared/ui/MoneyDisplay'
import { StatusChip } from '@/shared/ui/StatusChip'
import { DataTable } from '@/shared/ui/DataTable'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { fetchCreditDetail, repayCredit as repayCreditUseCase } from '@/usecases/creditUseCases'
import { formatDate } from '@/shared/utils/format'
import { CreditStatus } from '@/entities/common'
import type { CreditResponse, PaymentResponse } from '@/entities/credit'
import { ApiError } from '@/api'

export function CreditDetailPage() {
  const { id } = useParams<{ id: string }>()
  const { enqueueSnackbar } = useSnackbar()
  const [credit, setCredit] = useState<CreditResponse | null>(null)
  const [payments, setPayments] = useState<PaymentResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [repayOpen, setRepayOpen] = useState(false)
  const [repayAmount, setRepayAmount] = useState('')
  const [repaying, setRepaying] = useState(false)

  const creditId = Number(id)

  const fetchData = useCallback(async () => {
    try {
      const { credit: creditData, payments: paymentsData } = await fetchCreditDetail(creditId)
      setCredit(creditData)
      setPayments(paymentsData)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [creditId, enqueueSnackbar])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const handleRepay = async () => {
    const parsed = parseFloat(repayAmount)
    if (isNaN(parsed) || parsed <= 0) {
      enqueueSnackbar('Введите корректную сумму', { variant: 'warning' })
      return
    }

    setRepaying(true)
    try {
      await repayCreditUseCase(creditId, { amount: parsed })
      enqueueSnackbar('Платёж по кредиту выполнен', { variant: 'success' })
      setRepayOpen(false)
      setRepayAmount('')
      await fetchData()
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setRepaying(false)
    }
  }

  if (loading) {
    return (
      <PageLayout title="Кредит">
        <Skeleton variant="rounded" height={200} sx={{ mb: 3 }} />
        <Skeleton variant="rounded" height={300} />
      </PageLayout>
    )
  }

  if (!credit) {
    return <PageLayout title="Кредит не найден"><Typography>Кредит не найден</Typography></PageLayout>
  }

  return (
    <PageLayout
      title={`Кредит #${credit.id}`}
      breadcrumbs={[
        { label: 'Мои кредиты', href: '/client/credits' },
        { label: `Кредит #${credit.id}` },
      ]}
    >
      <Card sx={{ mb: 3 }}>
        <CardContent sx={{ p: 3 }}>
          <Grid container spacing={3}>
            <Grid size={{ xs: 12, md: 3 }}>
              <Typography variant="body2" color="text.secondary">Остаток</Typography>
              <MoneyDisplay amount={credit.remaining} currency={credit.currency} variant="h4" />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <Typography variant="body2" color="text.secondary">Сумма кредита</Typography>
              <MoneyDisplay amount={credit.principal} currency={credit.currency} variant="h6" />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <Typography variant="body2" color="text.secondary">Начислено %</Typography>
              <MoneyDisplay amount={credit.accruedInterest} currency={credit.currency} variant="h6" />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <Typography variant="body2" color="text.secondary">Ставка</Typography>
              <Typography variant="h6">{credit.interestRate}%</Typography>
            </Grid>
            <Grid size={{ xs: 6, md: 1.5 }}>
              <Typography variant="body2" color="text.secondary">Платёж/день</Typography>
              <MoneyDisplay amount={credit.dailyPayment} currency={credit.currency} variant="h6" />
            </Grid>
            <Grid size={{ xs: 6, md: 1.5 }}>
              <Typography variant="body2" color="text.secondary">Статус</Typography>
              <StatusChip status={credit.status} size="medium" />
            </Grid>
          </Grid>
          {credit.status === CreditStatus.ACTIVE && (
            <Button
              variant="contained"
              sx={{ mt: 3 }}
              onClick={() => setRepayOpen(true)}
            >
              Досрочное погашение
            </Button>
          )}
        </CardContent>
      </Card>

      <Typography variant="h6" sx={{ mb: 2 }}>Платежи</Typography>
      <DataTable
        columns={[
          { id: 'id', label: '#', render: (row: PaymentResponse) => <Typography variant="body2">{row.id}</Typography> },
          {
            id: 'amount',
            label: 'Сумма',
            align: 'right',
            render: (row: PaymentResponse) => <MoneyDisplay amount={row.amount} currency={row.currency} variant="body2" />,
          },
          { id: 'status', label: 'Статус', render: (row: PaymentResponse) => <StatusChip status={row.status} /> },
          {
            id: 'dueDate',
            label: 'Дата платежа',
            render: (row: PaymentResponse) => <Typography variant="body2">{formatDate(row.dueDate)}</Typography>,
          },
          {
            id: 'paidAt',
            label: 'Дата оплаты',
            render: (row: PaymentResponse) => (
              <Typography variant="body2" color="text.secondary">
                {row.paidAt ? formatDate(row.paidAt) : '—'}
              </Typography>
            ),
          },
        ]}
        rows={payments}
        getRowKey={(row) => row.id}
        emptyMessage="Нет платежей"
      />

      <Dialog open={repayOpen} onClose={() => setRepayOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Досрочное погашение</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Остаток по кредиту: {credit.remaining.toLocaleString('ru-RU')} ₽
          </Typography>
          <TextField
            autoFocus
            label="Сумма погашения"
            type="number"
            value={repayAmount}
            onChange={(e) => setRepayAmount(e.target.value)}
            fullWidth
            slotProps={{ htmlInput: { min: 0.01, step: 0.01 } }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRepayOpen(false)}>Отмена</Button>
          <LoadingButton variant="contained" loading={repaying} onClick={handleRepay}>
            Погасить
          </LoadingButton>
        </DialogActions>
      </Dialog>
    </PageLayout>
  )
}
