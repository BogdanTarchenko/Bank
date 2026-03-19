import { useMemo } from 'react'
import { RouterProvider } from 'react-router-dom'
import { ThemeProvider, CssBaseline } from '@mui/material'
import { SnackbarProvider } from 'notistack'
import { ErrorBoundary } from 'react-error-boundary'
import { router } from './routes'
import { getTheme } from './theme'
import { useSettingsStore } from '@/store/settingsStore'
import { ErrorPage } from '@/pages/ErrorPage'

export function App() {
  const themeMode = useSettingsStore((s) => s.theme)
  const muiTheme = useMemo(() => getTheme(themeMode), [themeMode])

  return (
    <ErrorBoundary FallbackComponent={ErrorPage}>
      <ThemeProvider theme={muiTheme}>
        <CssBaseline />
        <SnackbarProvider
          maxSnack={3}
          autoHideDuration={4000}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        >
          <RouterProvider router={router} />
        </SnackbarProvider>
      </ThemeProvider>
    </ErrorBoundary>
  )
}
