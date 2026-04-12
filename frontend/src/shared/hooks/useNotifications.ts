/**
 * Push notification hook.
 * Integrates Firebase FCM for push notifications about operations.
 *
 * - Client portal: registers FCM token → backend sends pushes for logged-in user's operations
 * - Employee portal: registers FCM token → backend sends pushes for ALL operations
 *
 * The backend already handles push delivery via PushNotificationService
 * when new operations arrive through Kafka. The frontend only needs to
 * register the FCM device token so the backend knows where to send pushes.
 */

import { useEffect, useRef } from 'react'
import { useSnackbar } from 'notistack'
import { initFirebase, requestNotificationPermission, onForegroundMessage } from '@/network/firebase'
import { httpClient } from '@/network/httpClient'
import { endpoints } from '@/network/endpoints'
import { useAuthStore } from '@/store/authStore'

export function useNotifications(): void {
  const { enqueueSnackbar } = useSnackbar()
  const { isAuthenticated, activeRole } = useAuthStore()
  const firebaseReady = useRef(false)
  const registeredToken = useRef<string | null>(null)

  // Firebase init + token registration on backend
  useEffect(() => {
    if (!isAuthenticated) return

    if (!firebaseReady.current) {
      const ok = initFirebase()
      if (!ok) return
      firebaseReady.current = true
    }

    requestNotificationPermission().then(async (token) => {
      if (!token) return

      // Unregister previous token from old portal if role switched
      if (registeredToken.current && registeredToken.current === token) {
        const prevPortal = activeRole === 'client' ? 'employee' : 'client'
        try {
          await httpClient.delete(endpoints[prevPortal].deviceTokens, {
            data: { fcmToken: token, platform: 'WEB' },
          })
        } catch {
          // ignore — may not have been registered on that portal
        }
      }

      // Register token on current portal's BFF
      try {
        await httpClient.post(endpoints[activeRole].deviceTokens, {
          fcmToken: token,
          platform: 'WEB',
        })
        registeredToken.current = token
        console.info(`[Notifications] FCM token registered on ${activeRole}-bff`)
      } catch (err) {
        console.error('[Notifications] Failed to register FCM token on backend:', err)
      }
    })
  }, [isAuthenticated, activeRole])

  // Foreground message handler — shows snackbar when push arrives while app is focused
  useEffect(() => {
    if (!isAuthenticated || !firebaseReady.current) return

    const unsub = onForegroundMessage((payload) => {
      enqueueSnackbar(`${payload.title}: ${payload.body}`, {
        variant: 'info',
        autoHideDuration: 6000,
      })
    })

    return () => {
      unsub?.()
    }
  }, [isAuthenticated, activeRole, enqueueSnackbar])
}
