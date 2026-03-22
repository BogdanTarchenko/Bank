import { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Typography,
  TextField,
  Box,
  Skeleton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
} from '@mui/material'
import AddIcon from '@mui/icons-material/Add'
import { useSnackbar } from 'notistack'
import { PageLayout } from '@/shared/ui/PageLayout'
import { DataTable } from '@/shared/ui/DataTable'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { userApi } from '@/api/userApi'
import { authApi } from '@/api/authApi'
import { formatDate } from '@/shared/utils/format'
import { Role, RoleLabel } from '@/entities/common'
import type { UserResponse } from '@/entities/user'
import { ApiError } from '@/network/httpClient'

export function UsersPage() {
  const navigate = useNavigate()
  const { enqueueSnackbar } = useSnackbar()
  const [users, setUsers] = useState<UserResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [createOpen, setCreateOpen] = useState(false)
  const [creating, setCreating] = useState(false)
  const [form, setForm] = useState({
    email: '',
    password: '',
    firstName: '',
    lastName: '',
    phone: '',
    roles: [Role.CLIENT] as Role[],
  })

  const fetchUsers = useCallback(async () => {
    try {
      const data = await userApi.getUsers('employee')
      setUsers(data)
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setLoading(false)
    }
  }, [enqueueSnackbar])

  useEffect(() => {
    fetchUsers()
  }, [fetchUsers])

  const handleCreate = async () => {
    if (!form.email || !form.password || !form.firstName || !form.lastName) {
      enqueueSnackbar('Заполните обязательные поля', { variant: 'warning' })
      return
    }
    setCreating(true)
    try {
      await authApi.register({
        email: form.email,
        password: form.password,
        firstName: form.firstName,
        lastName: form.lastName,
        phone: form.phone || undefined,
        roles: form.roles,
      })
      enqueueSnackbar('Пользователь создан', { variant: 'success' })
      setCreateOpen(false)
      setForm({ email: '', password: '', firstName: '', lastName: '', phone: '', roles: [Role.CLIENT] })
      await fetchUsers()
    } catch (err) {
      if (err instanceof ApiError) {
        enqueueSnackbar(err.message, { variant: 'error' })
      }
    } finally {
      setCreating(false)
    }
  }

  const filtered = users.filter((u) => {
    if (!search) return true
    const s = search.toLowerCase()
    return (
      u.email.toLowerCase().includes(s) ||
      u.firstName.toLowerCase().includes(s) ||
      u.lastName.toLowerCase().includes(s) ||
      u.id.toString().includes(s)
    )
  })

  if (loading) {
    return (
      <PageLayout title="Пользователи">
        <Skeleton variant="rounded" height={400} />
      </PageLayout>
    )
  }

  return (
    <PageLayout
      title="Пользователи"
      action={
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setCreateOpen(true)}>
          Создать пользователя
        </Button>
      }
    >
      <Box sx={{ mb: 3 }}>
        <TextField
          placeholder="Поиск по имени, email или ID..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          size="small"
          sx={{ width: 400 }}
        />
      </Box>
      <DataTable
        columns={[
          { id: 'id', label: 'ID', render: (row: UserResponse) => <Typography variant="body2">#{row.id}</Typography> },
          {
            id: 'name',
            label: 'Имя',
            render: (row: UserResponse) => <Typography variant="body2" fontWeight={600}>{row.firstName} {row.lastName}</Typography>,
          },
          { id: 'email', label: 'Email', render: (row: UserResponse) => <Typography variant="body2">{row.email}</Typography> },
          {
            id: 'roles',
            label: 'Роли',
            render: (row: UserResponse) => (
              <Box sx={{ display: 'flex', gap: 0.5 }}>
                {row.roles.map((r) => (
                  <Chip key={r} label={RoleLabel[r] ?? r} size="small" variant="outlined" />
                ))}
              </Box>
            ),
          },
          {
            id: 'status',
            label: 'Статус',
            render: (row: UserResponse) => (
              <Typography variant="body2" color={row.blocked ? 'error.main' : 'success.main'}>
                {row.blocked ? 'Заблокирован' : 'Активен'}
              </Typography>
            ),
          },
          {
            id: 'createdAt',
            label: 'Дата регистрации',
            render: (row: UserResponse) => <Typography variant="body2" color="text.secondary">{formatDate(row.createdAt)}</Typography>,
          },
        ]}
        rows={filtered}
        getRowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/employee/users/${row.id}`)}
        emptyMessage="Нет пользователей"
      />

      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Создать пользователя</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              label="Имя"
              value={form.firstName}
              onChange={(e) => setForm((p) => ({ ...p, firstName: e.target.value }))}
              required
            />
            <TextField
              label="Фамилия"
              value={form.lastName}
              onChange={(e) => setForm((p) => ({ ...p, lastName: e.target.value }))}
              required
            />
            <TextField
              label="Email"
              type="email"
              value={form.email}
              onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))}
              required
            />
            <TextField
              label="Пароль"
              type="password"
              value={form.password}
              onChange={(e) => setForm((p) => ({ ...p, password: e.target.value }))}
              required
            />
            <TextField
              label="Телефон"
              value={form.phone}
              onChange={(e) => setForm((p) => ({ ...p, phone: e.target.value }))}
            />
            <FormControl>
              <InputLabel>Роли</InputLabel>
              <Select
                value={form.roles.join(',')}
                label="Роли"
                onChange={(e) => {
                  const value = e.target.value
                  const roles = value.split(',').filter(Boolean) as Role[]
                  setForm((p) => ({ ...p, roles }))
                }}
              >
                {Object.values(Role).map((r) => (
                  <MenuItem key={r} value={r}>{RoleLabel[r] ?? r}</MenuItem>
                ))}
              </Select>
              <Box sx={{ display: 'flex', gap: 0.5, mt: 1 }}>
                {form.roles.map((r) => (
                  <Chip
                    key={r}
                    label={RoleLabel[r] ?? r}
                    size="small"
                    onDelete={() => setForm((p) => ({ ...p, roles: p.roles.filter((role) => role !== r) }))}
                  />
                ))}
              </Box>
            </FormControl>
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
