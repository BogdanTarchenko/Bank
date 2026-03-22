import { useEffect, useState, useCallback } from 'react'
import { useParams } from 'react-router-dom'
import {
  Card,
  CardContent,
  CardActionArea,
  Typography,
  Grid,
  Skeleton,
  Box,
} from '@mui/material'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { MoneyDisplay } from '@/shared/ui/MoneyDisplay'
import { StatusChip } from '@/shared/ui/StatusChip'
import { EmptyState } from '@/shared/ui/EmptyState'
import { DataTable } from '@/shared/ui/DataTable'
import { fetchUserCreditsWithRating, fetchCreditPayments } from '@/usecases/creditUseCases'
import { fetchUserById } from '@/usecases/userUseCases'
import { formatDateShort, formatDate } from '@/shared/utils/format'
import { Currency, CreditGradeLabel } from '@/entities/common'
import type { CreditResponse, PaymentResponse, CreditRatingResponse } from '@/entities/credit'
import type { UserResponse } from '@/entities/user'
import { ApiError } from '@/api'

export function ClientCreditsPage() {
  const { userId } = useParams<{ userId: string }>()
  const { enqueueSnackbar } = useSnackbar()
  const [user, setUser] = useState<UserResponse | null>(null)
  const [credits, setCredits] = useState<CreditResponse[]>([])
  const [rating, setRating] = useState<CreditRatingResponse | null>(null)
  const [selectedCredit, setSelectedCredit] = useState<CreditResponse | null>(null)
  const [payments, setPayments] = useState<PaymentResponse[]>([])
  const [loading, setLoading] = useState(true)

  const uid = Number(userId)

  const fetchData = useCallback(async () => {
    try {
      const [userData, { credits: creditsData, rating: ratingData }] = await Promise.all([
        fetchUserById(uid),
        fetchUserCreditsWithRating(uid),
      ])
      setUser(userData)
      setCredits(creditsData)
      setRating(ratingData)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [uid, enqueueSnackbar])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const handleSelectCredit = async (credit: CreditResponse) => {
    setSelectedCredit(credit)
    try {
      const data = await fetchCreditPayments(credit.id, 'employee')
      setPayments(data)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    }
  }

  if (loading) {
    return (
      <PageLayout title="Кредиты клиента">
        <Skeleton variant="rounded" height={120} sx={{ mb: 3 }} />
        <Skeleton variant="rounded" height={300} />
      </PageLayout>
    )
  }

  return (
    <PageLayout
      title={`Кредиты: ${user?.firstName} ${user?.lastName}`}
      breadcrumbs={[
        { label: 'Пользователи', href: '/employee/users' },
        { label: `${user?.firstName} ${user?.lastName}`, href: `/employee/users/${uid}` },
        { label: 'Кредиты' },
      ]}
    >
      {rating && (
        <Card sx={{ mb: 3 }}>
          <CardContent sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>Кредитный рейтинг</Typography>
            <Grid container spacing={3}>
              <Grid size={{ xs: 6, md: 3 }}>
                <Typography variant="body2" color="text.secondary">Оценка</Typography>
                <Typography variant="h4" color="primary.main">{rating.score}</Typography>
              </Grid>
              <Grid size={{ xs: 6, md: 3 }}>
                <Typography variant="body2" color="text.secondary">Категория</Typography>
                <Typography variant="h5">{CreditGradeLabel[rating.grade] ?? rating.grade}</Typography>
              </Grid>
              <Grid size={{ xs: 6, md: 3 }}>
                <Typography variant="body2" color="text.secondary">Активные</Typography>
                <Typography variant="h5">{rating.activeCredits}</Typography>
              </Grid>
              <Grid size={{ xs: 6, md: 3 }}>
                <Typography variant="body2" color="text.secondary">Просрочки</Typography>
                <Typography variant="h5" color={rating.overduePayments > 0 ? 'error.main' : 'success.main'}>
                  {rating.overduePayments}
                </Typography>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      )}

      {credits.length === 0 ? (
        <EmptyState title="У клиента нет кредитов" />
      ) : (
        <Grid container spacing={3} sx={{ mb: 3 }}>
          {credits.map((credit) => (
            <Grid size={{ xs: 12, sm: 6 }} key={credit.id}>
              <Card elevation={selectedCredit?.id === credit.id ? 4 : 1}>
                <CardActionArea onClick={() => handleSelectCredit(credit)}>
                  <CardContent sx={{ p: 3 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="subtitle1" fontWeight={600}>{credit.tariffName}</Typography>
                      <StatusChip status={credit.status} />
                    </Box>
                    <MoneyDisplay amount={credit.remaining} currency={Currency.RUB} variant="h5" sx={{ mb: 1 }} />
                    <Typography variant="body2" color="text.secondary">
                      из {credit.principal.toLocaleString('ru-RU')} ₽ • {credit.interestRate}% • {formatDateShort(credit.createdAt)}
                    </Typography>
                  </CardContent>
                </CardActionArea>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {selectedCredit && (
        <>
          <Typography variant="h6" sx={{ mb: 2 }}>
            Платежи по кредиту #{selectedCredit.id}
          </Typography>
          <DataTable
            columns={[
              { id: 'id', label: '#', render: (row: PaymentResponse) => <Typography variant="body2">{row.id}</Typography> },
              {
                id: 'amount',
                label: 'Сумма',
                align: 'right',
                render: (row: PaymentResponse) => <MoneyDisplay amount={row.amount} currency={Currency.RUB} variant="body2" />,
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
        </>
      )}
    </PageLayout>
  )
}
