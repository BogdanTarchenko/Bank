import { Box, Typography, Button } from '@mui/material'
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline'
import { useNavigate } from 'react-router-dom'

interface ErrorPageProps {
  error?: unknown
  resetErrorBoundary?: () => void
}

export function ErrorPage({ error, resetErrorBoundary }: ErrorPageProps) {
  const navigate = useNavigate()

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100vh',
        p: 3,
        textAlign: 'center',
      }}
    >
      <ErrorOutlineIcon sx={{ fontSize: 80, color: 'error.main', mb: 2 }} />
      <Typography variant="h4" gutterBottom>
        Что-то пошло не так
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3, maxWidth: 500 }}>
        {(error instanceof Error ? error.message : null) || 'Произошла непредвиденная ошибка. Попробуйте обновить страницу.'}
      </Typography>
      <Box sx={{ display: 'flex', gap: 2 }}>
        <Button
          variant="contained"
          onClick={() => {
            if (resetErrorBoundary) {
              resetErrorBoundary()
            } else {
              navigate('/')
              window.location.reload()
            }
          }}
        >
          Попробовать снова
        </Button>
        <Button variant="outlined" onClick={() => navigate('/')}>
          На главную
        </Button>
      </Box>
    </Box>
  )
}
