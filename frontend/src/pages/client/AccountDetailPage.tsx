import { useEffect, useState, useCallback } from 'react'
import { useParams, useNavigate, useLocation } from 'react-router-dom'
import {
  Box,
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
import { DataTable } from '@/shared/ui/DataTable'
import { StatusChip } from '@/shared/ui/StatusChip'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { ConfirmDialog } from '@/shared/ui/ConfirmDialog'
import {
  fetchAccount as fetchAccountUseCase,
  fetchOperationsPage,
  depositToAccount,
  withdrawFromAccount,
  closeAccount as closeAccountUseCase,
  subscribeToOperations,
} from '@/usecases/accountUseCases'
import { formatDate } from '@/shared/utils/format'
import { formatMoney } from '@/shared/utils/format'
import { OperationType, CurrencyLabel, OperationTypeLabel } from '@/entities/common'
import type { AccountResponse } from '@/entities/account'
import type { OperationResponse } from '@/entities/operation'
import { ApiError } from '@/api'

type ModalType = 'deposit' | 'withdraw' | null

export function AccountDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const location = useLocation()
  const { enqueueSnackbar } = useSnackbar()
  const portal = location.pathname.startsWith('/employee') ? 'employee' as const : 'client' as const
  const [account, setAccount] = useState<AccountResponse | null>(null)
  const [operations, setOperations] = useState<OperationResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(0)
  const [totalCount, setTotalCount] = useState(0)
  const [modal, setModal] = useState<ModalType>(null)
  const [amount, setAmount] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [closeDialog, setCloseDialog] = useState(false)
  const [closing, setClosing] = useState(false)

  const accountId = Number(id)

  const fetchAccount = useCallback(async () => {
    try {
      const data = await fetchAccountUseCase(accountId, portal)
      setAccount(data)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    }
  }, [accountId, portal, enqueueSnackbar])

  const fetchOperations = useCallback(async (p: number) => {
    try {
      const data = await fetchOperationsPage(accountId, p, 20, portal)
      setOperations(data.content)
      setTotalCount(data.totalElements)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    }
  }, [accountId, portal, enqueueSnackbar])

  useEffect(() => {
    Promise.all([fetchAccount(), fetchOperations(0)]).then(() => setLoading(false))
  }, [fetchAccount, fetchOperations])

  useEffect(() => {
    const unsubscribe = subscribeToOperations(accountId, (op) => {
      setOperations((prev) => [op, ...prev])
      setTotalCount((prev) => prev + 1)
      fetchAccount()
    })

    return () => {
      unsubscribe()
    }
  }, [accountId, fetchAccount])

  const handleMoneyOperation = async () => {
    if (!modal || !amount) return
    setSubmitting(true)
    try {
      const parsedAmount = parseFloat(amount)
      if (isNaN(parsedAmount) || parsedAmount <= 0) {
        enqueueSnackbar('Введите корректную сумму', { variant: 'warning' })
        return
      }
      if (modal === 'deposit') {
        await depositToAccount(accountId, { amount: parsedAmount })
        enqueueSnackbar('Пополнение отправлено', { variant: 'success' })
      } else {
        await withdrawFromAccount(accountId, { amount: parsedAmount })
        enqueueSnackbar('Снятие отправлено', { variant: 'success' })
      }
      setModal(null)
      setAmount('')
      setTimeout(() => {
        fetchAccount()
        fetchOperations(page)
      }, 1000)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setSubmitting(false)
    }
  }

  const handleCloseAccount = async () => {
    setClosing(true)
    try {
      await closeAccountUseCase(accountId)
      enqueueSnackbar('Счёт закрыт', { variant: 'success' })
      navigate(-1)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setClosing(false)
      setCloseDialog(false)
    }
  }

  if (loading) {
    return (
      <PageLayout title="Детали счёта">
        <Skeleton variant="rounded" height={160} sx={{ mb: 3 }} />
        <Skeleton variant="rounded" height={300} />
      </PageLayout>
    )
  }

  if (!account) {
    return <PageLayout title="Счёт не найден"><Typography>Счёт не найден</Typography></PageLayout>
  }

  const breadcrumbs = portal === 'client'
    ? [{ label: 'Мои счета', href: '/client/dashboard' }, { label: `Счёт #${account.id}` }]
    : [{ label: 'Все счета', href: '/employee/dashboard' }, { label: `Счёт #${account.id}` }]

  return (
    <PageLayout title={`Счёт #${account.id}`} breadcrumbs={breadcrumbs}>
      <Card sx={{ mb: 3 }}>
        <CardContent sx={{ p: 3 }}>
          <Grid container spacing={3}>
            <Grid size={{ xs: 12, md: 6 }}>
              <Typography variant="body2" color="text.secondary">Баланс</Typography>
              <MoneyDisplay amount={account.balance} currency={account.currency} variant="h4" />
            </Grid>
            <Grid size={{ xs: 6, md: 3 }}>
              <Typography variant="body2" color="text.secondary">Валюта</Typography>
              <Typography variant="h6">{CurrencyLabel[account.currency] ?? account.currency}</Typography>
            </Grid>
            <Grid size={{ xs: 6, md: 3 }}>
              <Typography variant="body2" color="text.secondary">Статус</Typography>
              <Typography variant="h6">{account.isClosed ? 'Закрыт' : 'Активен'}</Typography>
            </Grid>
          </Grid>
          {portal === 'client' && !account.isClosed && (
            <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
              <Button variant="contained" color="success" onClick={() => setModal('deposit')}>
                Пополнить
              </Button>
              <Button variant="contained" color="warning" onClick={() => setModal('withdraw')}>
                Снять
              </Button>
              <Button variant="outlined" color="error" onClick={() => setCloseDialog(true)}>
                Закрыть счёт
              </Button>
            </Box>
          )}
        </CardContent>
      </Card>

      <Typography variant="h6" sx={{ mb: 2 }}>История операций</Typography>
      <DataTable
        columns={[
          {
            id: 'type',
            label: 'Тип',
            render: (row: OperationResponse) => (
              <StatusChip status={row.type} />
            ),
          },
          {
            id: 'typeLabel',
            label: 'Описание',
            render: (row: OperationResponse) => (
              <Typography variant="body2">
                {row.description || OperationTypeLabel[row.type] || row.type}
              </Typography>
            ),
          },
          {
            id: 'amount',
            label: 'Сумма',
            align: 'right',
            render: (row: OperationResponse) => {
              const isIncoming = row.type === OperationType.DEPOSIT || row.type === OperationType.TRANSFER_IN
              return (
                <MoneyDisplay
                  amount={isIncoming ? row.amount : -row.amount}
                  currency={row.currency}
                  showSign
                  variant="body2"
                  fontWeight={600}
                />
              )
            },
          },
          {
            id: 'date',
            label: 'Дата',
            align: 'right',
            render: (row: OperationResponse) => (
              <Typography variant="body2" color="text.secondary">{formatDate(row.createdAt)}</Typography>
            ),
          },
        ]}
        rows={operations}
        getRowKey={(row) => row.id}
        page={page}
        totalCount={totalCount}
        onPageChange={(p) => {
          setPage(p)
          fetchOperations(p)
        }}
        emptyMessage="Нет операций"
      />

      <Dialog open={modal !== null} onClose={() => { setModal(null); setAmount('') }} maxWidth="xs" fullWidth>
        <DialogTitle>{modal === 'deposit' ? 'Пополнение счёта' : 'Снятие со счёта'}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            label="Сумма"
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            fullWidth
            sx={{ mt: 1 }}
            slotProps={{ htmlInput: { min: 0.01, step: 0.01 } }}
          />
          {account && (
            <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
              Текущий баланс: {formatMoney(account.balance, account.currency)}
            </Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setModal(null); setAmount('') }}>Отмена</Button>
          <LoadingButton
            variant="contained"
            loading={submitting}
            onClick={handleMoneyOperation}
            color={modal === 'deposit' ? 'success' : 'warning'}
          >
            {modal === 'deposit' ? 'Пополнить' : 'Снять'}
          </LoadingButton>
        </DialogActions>
      </Dialog>

      <ConfirmDialog
        open={closeDialog}
        title="Закрытие счёта"
        message="Вы уверены, что хотите закрыть этот счёт? Это действие необратимо."
        confirmText="Закрыть"
        color="error"
        loading={closing}
        onConfirm={handleCloseAccount}
        onCancel={() => setCloseDialog(false)}
      />
    </PageLayout>
  )
}
