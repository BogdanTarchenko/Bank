import { useEffect, useMemo, useRef } from 'react'
import { RouterProvider } from 'react-router-dom'
import { ThemeProvider, CssBaseline } from '@mui/material'
import { SnackbarProvider, useSnackbar } from 'notistack'
import { ErrorBoundary } from 'react-error-boundary'
import { router } from './routes'
import { getTheme } from './theme'
import { useSettingsStore } from '@/store/settingsStore'
import { ErrorPage } from '@/pages/ErrorPage'
import { initGlobalErrorHandlers, setGlobalErrorListener } from '@/shared/utils/globalErrorHandler'

/** Компонент-мост: подключает глобальный обработчик ошибок к snackbar */
function GlobalErrorBridge() {
  const { enqueueSnackbar } = useSnackbar()
  const snackbarRef = useRef(enqueueSnackbar)

  useEffect(() => {
    snackbarRef.current = enqueueSnackbar
  }, [enqueueSnackbar])

  useEffect(() => {
    setGlobalErrorListener((message) => {
      snackbarRef.current(message, { variant: 'error' })
    })
  }, [])

  return null
}

export function App() {
  const themeMode = useSettingsStore((s) => s.theme)
  const muiTheme = useMemo(() => getTheme(themeMode), [themeMode])

  useEffect(() => {
    initGlobalErrorHandlers()
  }, [])

  return (
    <ErrorBoundary FallbackComponent={ErrorPage}>
      <ThemeProvider theme={muiTheme}>
        <CssBaseline />
        <SnackbarProvider
          maxSnack={3}
          autoHideDuration={4000}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        >
          <GlobalErrorBridge />
          <RouterProvider router={router} />
        </SnackbarProvider>
      </ThemeProvider>
    </ErrorBoundary>
  )
}
