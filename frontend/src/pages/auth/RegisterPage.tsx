import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  Box,
  Paper,
  Typography,
  TextField,
  Alert,
  Link as MuiLink,
} from '@mui/material'
import AccountBalanceIcon from '@mui/icons-material/AccountBalance'
import { useSnackbar } from 'notistack'
import { LoadingButton } from '@/shared/ui/LoadingButton'
import { authApi } from '@/api/authApi'
import { ApiError } from '@/network/httpClient'

export function RegisterPage() {
  const navigate = useNavigate()
  const { enqueueSnackbar } = useSnackbar()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
    phone: '',
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    if (form.password !== form.confirmPassword) {
      setError('Пароли не совпадают')
      return
    }

    if (form.password.length < 6) {
      setError('Пароль должен содержать минимум 6 символов')
      return
    }

    setLoading(true)
    try {
      await authApi.register({
        email: form.email,
        password: form.password,
        firstName: form.firstName,
        lastName: form.lastName,
        phone: form.phone || undefined,
      })
      enqueueSnackbar('Регистрация прошла успешно! Теперь войдите в аккаунт.', { variant: 'success' })
      navigate('/login')
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('Ошибка при регистрации')
      }
    } finally {
      setLoading(false)
    }
  }

  const updateField = (field: string) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, [field]: e.target.value }))
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
        p: 2,
      }}
    >
      <Paper sx={{ p: 4, maxWidth: 420, width: '100%' }}>
        <Box sx={{ textAlign: 'center', mb: 3 }}>
          <AccountBalanceIcon sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
          <Typography variant="h5">Регистрация</Typography>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box component="form" onSubmit={handleSubmit}>
          <TextField
            label="Имя"
            value={form.firstName}
            onChange={updateField('firstName')}
            fullWidth
            required
            sx={{ mb: 2 }}
          />
          <TextField
            label="Фамилия"
            value={form.lastName}
            onChange={updateField('lastName')}
            fullWidth
            required
            sx={{ mb: 2 }}
          />
          <TextField
            label="Email"
            type="email"
            value={form.email}
            onChange={updateField('email')}
            fullWidth
            required
            sx={{ mb: 2 }}
          />
          <TextField
            label="Телефон"
            value={form.phone}
            onChange={updateField('phone')}
            fullWidth
            sx={{ mb: 2 }}
          />
          <TextField
            label="Пароль"
            type="password"
            value={form.password}
            onChange={updateField('password')}
            fullWidth
            required
            sx={{ mb: 2 }}
          />
          <TextField
            label="Подтверждение пароля"
            type="password"
            value={form.confirmPassword}
            onChange={updateField('confirmPassword')}
            fullWidth
            required
            sx={{ mb: 3 }}
          />
          <LoadingButton
            type="submit"
            variant="contained"
            fullWidth
            loading={loading}
            sx={{ mb: 2, py: 1.5 }}
          >
            Зарегистрироваться
          </LoadingButton>
          <Box sx={{ textAlign: 'center' }}>
            <MuiLink component={Link} to="/login" underline="hover">
              Уже есть аккаунт? Войти
            </MuiLink>
          </Box>
        </Box>
      </Paper>
    </Box>
  )
}
