import { Box, Button, Typography, Paper, Link as MuiLink } from '@mui/material'
import AccountBalanceIcon from '@mui/icons-material/AccountBalance'
import { Link } from 'react-router-dom'
import { startLogin } from '@/usecases/authUseCases'

export function LoginPage() {
  const handleLogin = () => {
    startLogin()
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
      <Paper sx={{ p: 5, maxWidth: 420, width: '100%', textAlign: 'center' }}>
        <AccountBalanceIcon sx={{ fontSize: 56, color: 'primary.main', mb: 2 }} />
        <Typography variant="h4" gutterBottom>
          Банк
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
          Войдите в свой аккаунт для управления финансами
        </Typography>
        <Button
          variant="contained"
          size="large"
          fullWidth
          onClick={handleLogin}
          sx={{ mb: 2, py: 1.5 }}
        >
          Войти
        </Button>
        <MuiLink component={Link} to="/register" underline="hover">
          Нет аккаунта? Зарегистрироваться
        </MuiLink>
      </Paper>
    </Box>
  )
}
