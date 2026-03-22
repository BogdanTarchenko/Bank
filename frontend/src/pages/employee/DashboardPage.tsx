import { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Typography, TextField, Box, Skeleton } from '@mui/material'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { DataTable } from '@/shared/ui/DataTable'
import { MoneyDisplay } from '@/shared/ui/MoneyDisplay'
import { fetchAllAccounts } from '@/usecases/accountUseCases'
import { formatDate } from '@/shared/utils/format'
import type { AccountResponse } from '@/entities/account'
import { CurrencyLabel } from '@/entities/common'
import { ApiError } from '@/api'

export function EmployeeDashboardPage() {
  const navigate = useNavigate()
  const { enqueueSnackbar } = useSnackbar()
  const [accounts, setAccounts] = useState<AccountResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')

  const fetchAccounts = useCallback(async () => {
    try {
      const data = await fetchAllAccounts()
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

  const filtered = accounts.filter((a) => {
    if (!search) return true
    const s = search.toLowerCase()
    return (
      a.id.toString().includes(s) ||
      a.userId.toString().includes(s) ||
      a.currency.toLowerCase().includes(s)
    )
  })

  if (loading) {
    return (
      <PageLayout title="Все счета">
        <Skeleton variant="rounded" height={400} />
      </PageLayout>
    )
  }

  return (
    <PageLayout title="Все счета">
      <Box sx={{ mb: 3 }}>
        <TextField
          placeholder="Поиск по ID счёта, пользователя или валюте..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          size="small"
          sx={{ width: 400 }}
        />
      </Box>
      <DataTable
        columns={[
          { id: 'id', label: 'ID', render: (row: AccountResponse) => <Typography variant="body2" fontWeight={600}>#{row.id}</Typography> },
          { id: 'userId', label: 'Пользователь', render: (row: AccountResponse) => <Typography variant="body2">#{row.userId}</Typography> },
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
        rows={filtered}
        getRowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/employee/accounts/${row.id}`)}
        emptyMessage="Нет счетов"
      />
    </PageLayout>
  )
}
