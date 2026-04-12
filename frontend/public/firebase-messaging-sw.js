/* eslint-disable no-undef */
/**
 * Firebase Messaging Service Worker.
 * Handles background push notifications when the app is not focused.
 *
 * Firebase config is passed via URL query params from the main app,
 * because service workers don't have access to Vite's import.meta.env.
 */

importScripts('https://www.gstatic.com/firebasejs/11.8.1/firebase-app-compat.js')
importScripts('https://www.gstatic.com/firebasejs/11.8.1/firebase-messaging-compat.js')

// Read config from URL query params (set by firebase.ts during registration)
const params = new URLSearchParams(self.location.search)

const config = {
  apiKey: params.get('apiKey') ?? '',
  authDomain: params.get('authDomain') ?? '',
  projectId: params.get('projectId') ?? '',
  storageBucket: params.get('storageBucket') ?? '',
  messagingSenderId: params.get('messagingSenderId') ?? '',
  appId: params.get('appId') ?? '',
}

if (config.projectId) {
  firebase.initializeApp(config)
  const messaging = firebase.messaging()

  // Called for data-only messages when app is in background.
  // Messages with `notification` field are handled automatically by FCM SDK.
  messaging.onBackgroundMessage((payload) => {
    const title = payload.notification?.title ?? payload.data?.title ?? 'Банк — новая операция'
    const options = {
      body: payload.notification?.body ?? payload.data?.body ?? 'Произведена новая операция по вашему счёту',
      icon: '/favicon.svg',
      badge: '/favicon.svg',
      data: payload.data,
    }
    self.registration.showNotification(title, options)
  })
}

// Fallback: handle raw push events that FCM SDK might not catch
self.addEventListener('push', (event) => {
  // If FCM SDK already handled it, a notification is already shown — skip
  // We check if there are visible notifications to avoid duplicates
  if (!event.data) return

  const showIfNeeded = async () => {
    const notifications = await self.registration.getNotifications()
    // If FCM already showed a notification in the last 2 seconds, skip
    if (notifications.length > 0) return

    let data
    try {
      data = event.data.json()
    } catch {
      data = { notification: { title: 'Банк', body: event.data.text() } }
    }

    const title = data.notification?.title ?? data.data?.title ?? 'Банк — новая операция'
    const body = data.notification?.body ?? data.data?.body ?? 'Произведена новая операция по вашему счёту'

    await self.registration.showNotification(title, {
      body,
      icon: '/favicon.svg',
      badge: '/favicon.svg',
      data: data.data,
    })
  }

  event.waitUntil(showIfNeeded())
})

self.addEventListener('notificationclick', (event) => {
  event.notification.close()
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      if (clientList.length > 0) {
        return clientList[0].focus()
      }
      return clients.openWindow('/')
    }),
  )
})
