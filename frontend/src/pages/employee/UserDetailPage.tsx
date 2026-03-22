import { useEffect, useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  Card,
  CardContent,
  Typography,
  Grid,
  Skeleton,
  Button,
  Chip,
  Box,
  Checkbox,
  FormControlLabel,
  FormGroup,
} from '@mui/material'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { ConfirmDialog } from '@/shared/ui/ConfirmDialog'
import { DataTable } from '@/shared/ui/DataTable'
import { MoneyDisplay } from '@/shared/ui/MoneyDisplay'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { userApi } from '@/api/userApi'
import { accountApi } from '@/api/accountApi'
import { creditApi } from '@/api/creditApi'
import { formatDate } from '@/shared/utils/format'
import { RoleLabel, CreditGradeLabel, CurrencyLabel } from '@/entities/common'
import type { UserResponse } from '@/entities/user'
import type { AccountResponse } from '@/entities/account'
import type { CreditRatingResponse } from '@/entities/credit'
import { ApiError } from '@/network/httpClient'

export function UserDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { enqueueSnackbar } = useSnackbar()
  const [user, setUser] = useState<UserResponse | null>(null)
  const [accounts, setAccounts] = useState<AccountResponse[]>([])
  const [rating, setRating] = useState<CreditRatingResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [blockDialog, setBlockDialog] = useState(false)
  const [blocking, setBlocking] = useState(false)
  const [availableRoles, setAvailableRoles] = useState<string[]>([])
  const [selectedRoles, setSelectedRoles] = useState<string[]>([])
  const [savingRoles, setSavingRoles] = useState(false)

  const userId = Number(id)

  const rolesChanged = user
    ? JSON.stringify([...selectedRoles].sort()) !== JSON.stringify([...user.roles].sort())
    : false

  const fetchData = useCallback(async () => {
    try {
      const [userData, accsData, ratingData, roles] = await Promise.all([
        userApi.getUser(userId, 'employee'),
        accountApi.getAccounts(userId, 'employee'),
        creditApi.getCreditRating(userId, 'employee').catch(() => null),
        userApi.getAvailableRoles().catch(() => []),
      ])
      setUser(userData)
      setAccounts(accsData)
      setRating(ratingData)
      setAvailableRoles(roles)
      setSelectedRoles(userData.roles)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [userId, enqueueSnackbar])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const handleSaveRoles = async () => {
    if (selectedRoles.length === 0) {
      enqueueSnackbar('Должна быть указана хотя бы одна роль', { variant: 'warning' })
      return
    }
    setSavingRoles(true)
    try {
      const updated = await userApi.updateUserRoles(userId, selectedRoles)
      setUser(updated)
      setSelectedRoles(updated.roles)
      enqueueSnackbar('Роли обновлены', { variant: 'success' })
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setSavingRoles(false)
    }
  }

  const handleBlockToggle = async () => {
    if (!user) return
    setBlocking(true)
    try {
      if (user.blocked) {
        await userApi.unblockUser(userId)
        enqueueSnackbar('Пользователь разблокирован', { variant: 'success' })
      } else {
        await userApi.blockUser(userId)
        enqueueSnackbar('Пользователь заблокирован', { variant: 'success' })
      }
      setBlockDialog(false)
      await fetchData()
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setBlocking(false)
    }
  }

  if (loading) {
    return (
      <PageLayout title="Пользователь">
        <Skeleton variant="rounded" height={200} sx={{ mb: 3 }} />
        <Skeleton variant="rounded" height={300} />
      </PageLayout>
    )
  }

  if (!user) {
    return <PageLayout title="Пользователь не найден"><Typography>Пользователь не найден</Typography></PageLayout>
  }

  return (
    <PageLayout
      title={`${user.firstName} ${user.lastName}`}
      breadcrumbs={[
        { label: 'Пользователи', href: '/employee/users' },
        { label: `${user.firstName} ${user.lastName}` },
      ]}
    >
      <Card sx={{ mb: 3 }}>
        <CardContent sx={{ p: 3 }}>
          <Grid container spacing={3}>
            <Grid size={{ xs: 12, md: 6 }}>
              <Typography variant="body2" color="text.secondary">Email</Typography>
              <Typography variant="h6">{user.email}</Typography>
            </Grid>
            <Grid size={{ xs: 6, md: 3 }}>
              <Typography variant="body2" color="text.secondary">Телефон</Typography>
              <Typography variant="h6">{user.phone || '—'}</Typography>
            </Grid>
            <Grid size={{ xs: 6, md: 3 }}>
              <Typography variant="body2" color="text.secondary">Статус</Typography>
              <Typography variant="h6" color={user.blocked ? 'error.main' : 'success.main'}>
                {user.blocked ? 'Заблокирован' : 'Активен'}
              </Typography>
            </Grid>
            <Grid size={{ xs: 12 }}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>Роли</Typography>
              {availableRoles.length > 0 ? (
                <Box>
                  <FormGroup row>
                    {availableRoles.map((role) => (
                      <FormControlLabel
                        key={role}
                        control={
                          <Checkbox
                            checked={selectedRoles.includes(role)}
                            onChange={(e) => {
                              if (e.target.checked) {
                                setSelectedRoles((prev) => [...prev, role])
                              } else {
                                setSelectedRoles((prev) => prev.filter((r) => r !== role))
                              }
                            }}
                          />
                        }
                        label={RoleLabel[role] ?? role}
                      />
                    ))}
                  </FormGroup>
                  {rolesChanged && (
                    <LoadingButton
                      variant="contained"
                      size="small"
                      loading={savingRoles}
                      onClick={handleSaveRoles}
                      sx={{ mt: 1 }}
                    >
                      Сохранить роли
                    </LoadingButton>
                  )}
                </Box>
              ) : (
                <Box sx={{ display: 'flex', gap: 0.5 }}>
                  {user.roles.map((r) => <Chip key={r} label={RoleLabel[r] ?? r} size="small" />)}
                </Box>
              )}
            </Grid>
          </Grid>
          <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
            <LoadingButton
              variant={user.blocked ? 'contained' : 'outlined'}
              color={user.blocked ? 'success' : 'error'}
              onClick={() => setBlockDialog(true)}
            >
              {user.blocked ? 'Разблокировать' : 'Заблокировать'}
            </LoadingButton>
            <Button variant="outlined" onClick={() => navigate(`/employee/users/${userId}/credits`)}>
              Кредиты
            </Button>
          </Box>
        </CardContent>
      </Card>

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

      <Typography variant="h6" sx={{ mb: 2 }}>Счета пользователя</Typography>
      <DataTable
        columns={[
          { id: 'id', label: 'ID', render: (row: AccountResponse) => <Typography variant="body2">#{row.id}</Typography> },
          { id: 'currency', label: 'Валюта', render: (row: AccountResponse) => <Typography variant="body2">{CurrencyLabel[row.currency] ?? row.currency}</Typography> },
          {
            id: 'balance',
            label: 'Баланс',
            align: 'right',
            render: (row: AccountResponse) => <MoneyDisplay amount={row.balance} currency={row.currency} variant="body2" fontWeight={600} />,
          },
          {
            id: 'status',
            label: 'Статус',
            render: (row: AccountResponse) => (
              <Typography variant="body2" color={row.isClosed ? 'error.main' : 'success.main'}>
                {row.isClosed ? 'Закрыт' : 'Активен'}
              </Typography>
            ),
          },
          {
            id: 'createdAt',
            label: 'Дата создания',
            render: (row: AccountResponse) => <Typography variant="body2" color="text.secondary">{formatDate(row.createdAt)}</Typography>,
          },
        ]}
        rows={accounts}
        getRowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/employee/accounts/${row.id}`)}
        emptyMessage="Нет счетов"
      />

      <ConfirmDialog
        open={blockDialog}
        title={user.blocked ? 'Разблокировать пользователя' : 'Заблокировать пользователя'}
        message={user.blocked
          ? `Разблокировать ${user.firstName} ${user.lastName}?`
          : `Заблокировать ${user.firstName} ${user.lastName}? Пользователь не сможет войти в систему.`}
        confirmText={user.blocked ? 'Разблокировать' : 'Заблокировать'}
        color={user.blocked ? 'primary' : 'error'}
        loading={blocking}
        onConfirm={handleBlockToggle}
        onCancel={() => setBlockDialog(false)}
      />
    </PageLayout>
  )
}
