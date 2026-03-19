import { useEffect, useRef, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Box, CircularProgress, Typography } from '@mui/material'
import { authApi } from '@/api/authApi'
import { useAuthStore } from '@/store/authStore'

export function CallbackPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const setAuth = useAuthStore((s) => s.setAuth)
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

    authApi
      .exchangeCode(code, state)
      .then(async (tokenResponse) => {
        localStorage.setItem('access_token', tokenResponse.access_token)
        if (tokenResponse.refresh_token) {
          localStorage.setItem('refresh_token', tokenResponse.refresh_token)
        }
        const userInfo = await authApi.getUserInfo()
        setAuth(userInfo, tokenResponse.access_token, tokenResponse.refresh_token)
        navigate('/client/dashboard', { replace: true })
      })
      .catch((err: unknown) => {
        const message = err instanceof Error ? err.message : 'Неизвестная ошибка'
        setError(message)
      })
  }, [searchParams, navigate, setAuth])

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
