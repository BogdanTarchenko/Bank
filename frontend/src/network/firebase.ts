/**
 * Firebase Cloud Messaging (FCM) for push notifications.
 *
 * Handles:
 * - Foreground notifications (shown via notistack snackbar)
 * - Background notifications (via service worker)
 * - FCM token registration
 *
 * Firebase config should be provided via environment variables.
 * See .env.example for required values.
 */

import { initializeApp, type FirebaseApp } from 'firebase/app'
import { getMessaging, getToken, onMessage, type Messaging } from 'firebase/messaging'

let app: FirebaseApp | null = null
let messaging: Messaging | null = null

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY ?? '',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ?? '',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID ?? '',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET ?? '',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? '',
  appId: import.meta.env.VITE_FIREBASE_APP_ID ?? '',
}

function isConfigured(): boolean {
  return !!(firebaseConfig.apiKey && firebaseConfig.projectId)
}

export function initFirebase(): boolean {
  if (!isConfigured()) {
    console.warn('[Firebase] Not configured — push notifications disabled. Set VITE_FIREBASE_* env vars.')
    return false
  }

  try {
    app = initializeApp(firebaseConfig)
    messaging = getMessaging(app)
    return true
  } catch (err) {
    console.error('[Firebase] Initialization failed:', err)
    return false
  }
}

/**
 * Request notification permission and get FCM token.
 * Returns the token string, or null if permission denied / not configured.
 */
export async function requestNotificationPermission(): Promise<string | null> {
  if (!messaging) return null

  try {
    const permission = await Notification.requestPermission()
    if (permission !== 'granted') {
      console.info('[Firebase] Notification permission denied')
      return null
    }

    const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY ?? ''

    // Pass Firebase config as URL params — service workers can't access import.meta.env
    const swParams = new URLSearchParams({
      apiKey: firebaseConfig.apiKey,
      authDomain: firebaseConfig.authDomain,
      projectId: firebaseConfig.projectId,
      storageBucket: firebaseConfig.storageBucket,
      messagingSenderId: firebaseConfig.messagingSenderId,
      appId: firebaseConfig.appId,
    })
    const swRegistration = await navigator.serviceWorker.register(
      `/firebase-messaging-sw.js?${swParams.toString()}`,
      { updateViaCache: 'none' },
    )
    // Force update to pick up new SW code
    await swRegistration.update()

    // Wait for the service worker to become active before requesting token
    await new Promise<void>((resolve) => {
      if (swRegistration.active) {
        resolve()
        return
      }
      const sw = swRegistration.installing ?? swRegistration.waiting
      if (!sw) {
        resolve()
        return
      }
      sw.addEventListener('statechange', function handler() {
        if (sw.state === 'activated') {
          sw.removeEventListener('statechange', handler)
          resolve()
        }
      })
    })

    const token = await getToken(messaging, {
      vapidKey,
      serviceWorkerRegistration: swRegistration,
    })

    console.info('[Firebase] FCM token obtained:', token.slice(0, 20) + '...')
    return token
  } catch (err) {
    console.error('[Firebase] Failed to get FCM token:', err)
    return null
  }
}

export type NotificationHandler = (payload: {
  title: string
  body: string
  data?: Record<string, string>
}) => void

/**
 * Listen for foreground FCM messages.
 * Returns unsubscribe function.
 */
export function onForegroundMessage(handler: NotificationHandler): (() => void) | null {
  if (!messaging) return null

  const unsubscribe = onMessage(messaging, (payload) => {
    handler({
      title: payload.notification?.title ?? 'Уведомление',
      body: payload.notification?.body ?? '',
      data: payload.data,
    })
  })

  return unsubscribe
}
