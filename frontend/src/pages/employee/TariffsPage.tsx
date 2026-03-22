import { useEffect, useState, useCallback } from 'react'
import {
  Typography,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Box,
  Skeleton,
} from '@mui/material'
import AddIcon from '@mui/icons-material/Add'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { DataTable } from '@/shared/ui/DataTable'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { fetchTariffs as fetchTariffsUseCase, createTariff as createTariffUseCase } from '@/usecases/creditUseCases'
import { formatDate } from '@/shared/utils/format'
import type { TariffResponse } from '@/entities/credit'
import { ApiError } from '@/api'

export function TariffsPage() {
  const { enqueueSnackbar } = useSnackbar()
  const [tariffs, setTariffs] = useState<TariffResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [createOpen, setCreateOpen] = useState(false)
  const [creating, setCreating] = useState(false)
  const [form, setForm] = useState({
    name: '',
    interestRate: '',
    minAmount: '',
    maxAmount: '',
    minTermDays: '',
    maxTermDays: '',
  })

  const fetchTariffs = useCallback(async () => {
    try {
      const data = await fetchTariffsUseCase('employee')
      setTariffs(data)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [enqueueSnackbar])

  useEffect(() => {
    fetchTariffs()
  }, [fetchTariffs])

  const handleCreate = async () => {
    if (!form.name || !form.interestRate || !form.minTermDays) {
      enqueueSnackbar('Заполните обязательные поля', { variant: 'warning' })
      return
    }
    setCreating(true)
    try {
      await createTariffUseCase({
        name: form.name,
        interestRate: parseFloat(form.interestRate),
        minAmount: form.minAmount ? parseFloat(form.minAmount) : undefined,
        maxAmount: form.maxAmount ? parseFloat(form.maxAmount) : undefined,
        minTermDays: parseInt(form.minTermDays),
        maxTermDays: form.maxTermDays ? parseInt(form.maxTermDays) : undefined,
      })
      enqueueSnackbar('Тариф создан', { variant: 'success' })
      setCreateOpen(false)
      setForm({ name: '', interestRate: '', minAmount: '', maxAmount: '', minTermDays: '', maxTermDays: '' })
      await fetchTariffs()
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setCreating(false)
    }
  }

  if (loading) {
    return (
      <PageLayout title="Кредитные тарифы">
        <Skeleton variant="rounded" height={400} />
      </PageLayout>
    )
  }

  return (
    <PageLayout
      title="Кредитные тарифы"
      action={
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setCreateOpen(true)}>
          Создать тариф
        </Button>
      }
    >
      <DataTable
        columns={[
          { id: 'id', label: 'ID', render: (row: TariffResponse) => <Typography variant="body2">#{row.id}</Typography> },
          { id: 'name', label: 'Название', render: (row: TariffResponse) => <Typography variant="body2" fontWeight={600}>{row.name}</Typography> },
          { id: 'rate', label: 'Ставка', render: (row: TariffResponse) => <Typography variant="body2">{row.interestRate}%</Typography> },
          {
            id: 'amount',
            label: 'Сумма',
            render: (row: TariffResponse) => (
              <Typography variant="body2">
                {row.minAmount?.toLocaleString('ru-RU') ?? '—'} — {row.maxAmount?.toLocaleString('ru-RU') ?? '—'} ₽
              </Typography>
            ),
          },
          {
            id: 'term',
            label: 'Срок (дней)',
            render: (row: TariffResponse) => (
              <Typography variant="body2">
                {row.minTermDays} — {row.maxTermDays ?? '∞'}
              </Typography>
            ),
          },
          {
            id: 'status',
            label: 'Активен',
            render: (row: TariffResponse) => (
              <Typography variant="body2" color={row.active ? 'success.main' : 'text.secondary'}>
                {row.active ? 'Да' : 'Нет'}
              </Typography>
            ),
          },
          {
            id: 'createdAt',
            label: 'Дата создания',
            render: (row: TariffResponse) => <Typography variant="body2" color="text.secondary">{formatDate(row.createdAt)}</Typography>,
          },
        ]}
        rows={tariffs}
        getRowKey={(row) => row.id}
        emptyMessage="Нет тарифов"
      />

      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Создать тариф</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              label="Название"
              value={form.name}
              onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
              required
            />
            <TextField
              label="Процентная ставка (%)"
              type="number"
              value={form.interestRate}
              onChange={(e) => setForm((p) => ({ ...p, interestRate: e.target.value }))}
              required
              slotProps={{ htmlInput: { min: 0.01, step: 0.01 } }}
            />
            <TextField
              label="Мин. сумма"
              type="number"
              value={form.minAmount}
              onChange={(e) => setForm((p) => ({ ...p, minAmount: e.target.value }))}
            />
            <TextField
              label="Макс. сумма"
              type="number"
              value={form.maxAmount}
              onChange={(e) => setForm((p) => ({ ...p, maxAmount: e.target.value }))}
            />
            <TextField
              label="Мин. срок (дней)"
              type="number"
              value={form.minTermDays}
              onChange={(e) => setForm((p) => ({ ...p, minTermDays: e.target.value }))}
              required
              slotProps={{ htmlInput: { min: 1 } }}
            />
            <TextField
              label="Макс. срок (дней)"
              type="number"
              value={form.maxTermDays}
              onChange={(e) => setForm((p) => ({ ...p, maxTermDays: e.target.value }))}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateOpen(false)}>Отмена</Button>
          <LoadingButton variant="contained" loading={creating} onClick={handleCreate}>
            Создать
          </LoadingButton>
        </DialogActions>
      </Dialog>
    </PageLayout>
  )
}
