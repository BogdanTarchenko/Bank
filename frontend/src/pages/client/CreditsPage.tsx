import { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Card,
  CardContent,
  CardActionArea,
  Typography,
  Grid,
  Skeleton,
  Button,
  Box,
} from '@mui/material'
import AddIcon from '@mui/icons-material/Add'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { MoneyDisplay } from '@/shared/ui/MoneyDisplay'
import { StatusChip } from '@/shared/ui/StatusChip'
import { EmptyState } from '@/shared/ui/EmptyState'
import { creditApi } from '@/api/creditApi'
import { useAuthStore } from '@/store/authStore'
import { formatDateShort } from '@/shared/utils/format'
import type { CreditResponse } from '@/entities/credit'
import type { CreditRatingResponse } from '@/entities/credit'
import { Currency } from '@/entities/common'
import { ApiError } from '@/network/httpClient'

export function CreditsPage() {
  const navigate = useNavigate()
  const { enqueueSnackbar } = useSnackbar()
  const user = useAuthStore((s) => s.user)
  const [credits, setCredits] = useState<CreditResponse[]>([])
  const [rating, setRating] = useState<CreditRatingResponse | null>(null)
  const [loading, setLoading] = useState(true)

  const fetchData = useCallback(async () => {
    if (!user) return
    try {
      const [creditsData, ratingData] = await Promise.all([
        creditApi.getCredits(user.userId),
        creditApi.getCreditRating(user.userId),
      ])
      setCredits(creditsData)
      setRating(ratingData)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [user, enqueueSnackbar])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  if (loading) {
    return (
      <PageLayout title="Мои кредиты">
        <Skeleton variant="rounded" height={120} sx={{ mb: 3 }} />
        <Grid container spacing={3}>
          {[1, 2].map((i) => (
            <Grid size={{ xs: 12, sm: 6 }} key={i}>
              <Skeleton variant="rounded" height={160} />
            </Grid>
          ))}
        </Grid>
      </PageLayout>
    )
  }

  return (
    <PageLayout
      title="Мои кредиты"
      action={
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => navigate('/client/credits/new')}>
          Взять кредит
        </Button>
      }
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
                <Typography variant="h5">{rating.grade}</Typography>
              </Grid>
              <Grid size={{ xs: 6, md: 3 }}>
                <Typography variant="body2" color="text.secondary">Всего кредитов</Typography>
                <Typography variant="h5">{rating.totalCredits}</Typography>
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
        <EmptyState
          title="Нет кредитов"
          description="Вы можете взять кредит по одному из доступных тарифов"
          action={
            <Button variant="contained" onClick={() => navigate('/client/credits/new')}>
              Взять кредит
            </Button>
          }
        />
      ) : (
        <Grid container spacing={3}>
          {credits.map((credit) => (
            <Grid size={{ xs: 12, sm: 6 }} key={credit.id}>
              <Card elevation={2}>
                <CardActionArea onClick={() => navigate(`/client/credits/${credit.id}`)}>
                  <CardContent sx={{ p: 3 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="subtitle1" fontWeight={600}>
                        {credit.tariffName}
                      </Typography>
                      <StatusChip status={credit.status} />
                    </Box>
                    <MoneyDisplay amount={credit.remaining} currency={Currency.RUB} variant="h5" sx={{ mb: 1 }} />
                    <Typography variant="body2" color="text.secondary">
                      из {credit.principal.toLocaleString('ru-RU')} ₽ • {credit.interestRate}% годовых
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Дата: {formatDateShort(credit.createdAt)} • {credit.termDays} дней
                    </Typography>
                  </CardContent>
                </CardActionArea>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}
    </PageLayout>
  )
}
