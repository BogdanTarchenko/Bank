import { useEffect, useRef, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Box, CircularProgress, Typography } from '@mui/material'
import { handleAuthCallback } from '@/usecases/authUseCases'

export function CallbackPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [error, setError] = useState<string | null>(null)
  const processedRef = useRef(false)

  useEffect(() => {
    if (processedRef.current) return
    processedRef.current = true

    const code = searchParams.get('code')
    const state = searchParams.get('state')
    const errorParam = searchParams.get('error')

    if (errorParam) {
      setError(`Ошибка авторизации: ${errorParam}`)
      return
    }

    if (!code || !state) {
      setError('Отсутствуют параметры авторизации')
      return
    }

    handleAuthCallback(code, state)
      .then(({ role }) => {
        navigate(`/${role}/dashboard`, { replace: true })
      })
      .catch((err: unknown) => {
        const message = err instanceof Error ? err.message : 'Неизвестная ошибка'
        setError(message)
      })
  }, [searchParams, navigate])

  if (error) {
    return (
      <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 2 }}>
        <Typography color="error" variant="h6">{error}</Typography>
        <Typography
          variant="body2"
          color="primary"
          sx={{ cursor: 'pointer' }}
          onClick={() => navigate('/login')}
        >
          Вернуться к логину
        </Typography>
      </Box>
    )
  }

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 2 }}>
      <CircularProgress />
      <Typography>Авторизация...</Typography>
    </Box>
  )
}
