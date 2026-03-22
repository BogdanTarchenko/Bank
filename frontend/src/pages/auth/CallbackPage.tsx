import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Box, CircularProgress, Typography } from '@mui/material'
import { handleAuthCallback } from '@/usecases/authUseCases'

export function CallbackPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [asyncError, setAsyncError] = useState<string | null>(null)
  const processedRef = useRef(false)

  const code = searchParams.get('code')
  const state = searchParams.get('state')
  const errorParam = searchParams.get('error')

  const immediateError = useMemo(() => {
    if (errorParam) return `Ошибка авторизации: ${errorParam}`
    if (!code || !state) return 'Отсутствуют параметры авторизации'
    return null
  }, [errorParam, code, state])

  useEffect(() => {
    if (processedRef.current || immediateError || !code || !state) return
    processedRef.current = true

    handleAuthCallback(code, state)
      .then(({ role }) => {
        navigate(`/${role}/dashboard`, { replace: true })
      })
      .catch((err: unknown) => {
        const message = err instanceof Error ? err.message : 'Неизвестная ошибка'
        setAsyncError(message)
      })
  }, [code, state, immediateError, navigate])

  const error = immediateError ?? asyncError

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
