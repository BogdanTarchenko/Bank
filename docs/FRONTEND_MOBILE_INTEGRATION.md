# Frontend & Mobile Integration Guide

Руководство по интеграции веб и мобильных приложений с банковским бэкендом.

---

## 1. Обзор изменений

В систему были добавлены следующие компоненты и механизмы:

| Компонент | Описание |
|-----------|----------|
| **monitoring-service** (порт 8086) | Новый сервис для сбора метрик со всех сервисов. Имеет REST API для приёма метрик и веб-дашборд по адресу `/dashboard`. |
| **ChaosFilter** | Намеренная нестабильность в core-service, user-service, credit-service: 30% случайных 500-ошибок в обычное время, 70% — на чётных минутах. Клиент обязан корректно обрабатывать сбои. |
| **TracingFilter** | Все сервисы генерируют и пробрасывают заголовок `X-Trace-Id` через всю цепочку запросов. |
| **IdempotencyFilter** | client-bff и employee-bff поддерживают заголовок `Idempotency-Key` для POST/PUT/PATCH запросов. Повторный запрос с тем же ключом вернёт кешированный ответ. |
| **Resilience4j** | Retry и Circuit Breaker реализованы на уровне BFF-сервисов и credit-service. |
| **Firebase Push Notifications** | Эндпоинты для регистрации FCM-токенов устройств. Пуш-уведомления отправляются при поступлении новых операций по счёту. |

Ключевые последствия для клиентских приложений:
- Необходимо реализовать **собственный Circuit Breaker и Retry** — бэкенд нестабилен намеренно.
- Все изменяющие состояние запросы должны содержать **Idempotency-Key**.
- Каждый запрос должен передавать **X-Trace-Id** для сквозной трассировки.
- После логина необходимо **зарегистрировать FCM-токен** для получения пуш-уведомлений.
- Рекомендуется отправлять **метрики** в monitoring-service для наблюдаемости.

---

## 2. Push-уведомления (Firebase FCM)

### 2.1 Регистрация устройства

После успешного логина приложение должно зарегистрировать FCM-токен устройства. Без этого пуш-уведомления приходить не будут.

**Запрос:**
```http
POST /api/v1/device-tokens
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "fcmToken": "<FCM_TOKEN>",
  "platform": "IOS"
}
```

Поле `platform` принимает одно из значений: `IOS` | `ANDROID` | `WEB`.

**Ответ:**
```
200 OK
```

Рекомендуется вызывать этот эндпоинт:
- При каждом запуске приложения после логина (FCM-токен может обновиться).
- При получении нового токена от Firebase (callback `onTokenRefresh` на Android, `didRegisterForRemoteNotificationsWithDeviceToken` на iOS).

### 2.2 Отмена регистрации

При логауте необходимо удалить токен устройства, чтобы уведомления не приходили после выхода из аккаунта.

**Запрос:**
```http
DELETE /api/v1/device-tokens
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "fcmToken": "<FCM_TOKEN>",
  "platform": "IOS"
}
```

**Ответ:**
```
200 OK
```

### 2.3 Структура push-уведомления

Клиент получает стандартное FCM-уведомление следующей структуры:

```json
{
  "notification": {
    "title": "Новая операция",
    "body": "По вашему счёту совершена операция"
  }
}
```

На iOS уведомление отображается системой автоматически, если приложение находится в фоне или закрыто. При активном приложении необходимо обработать его самостоятельно через делегат `UNUserNotificationCenterDelegate`.

На Android уведомление отображается системой автоматически при фоновом режиме. При активном приложении обработка происходит через `FirebaseMessagingService.onMessageReceived`.

### 2.4 Настройка Firebase

**iOS:**
1. Создайте приложение в Firebase Console и скачайте `GoogleService-Info.plist`.
2. Добавьте файл в корень Xcode-проекта (убедитесь, что он включён в Target Membership).
3. Добавьте зависимость `FirebaseMessaging` через Swift Package Manager или CocoaPods.
4. Инициализируйте Firebase в `AppDelegate`:
   ```swift
   import Firebase

   func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       FirebaseApp.configure()
       return true
   }
   ```
5. Запросите разрешение на уведомления и зарегистрируйте APNs.

**Android:**
1. Создайте приложение в Firebase Console и скачайте `google-services.json`.
2. Поместите файл в директорию `app/`.
3. Добавьте плагин и зависимости в `build.gradle`:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }

   dependencies {
       implementation("com.google.firebase:firebase-messaging-ktx")
   }
   ```
4. Реализуйте `FirebaseMessagingService` для обработки входящих сообщений и обновлений токена.

**Web:**
1. Установите Firebase SDK: `npm install firebase`.
2. Инициализируйте приложение с конфигурацией из Firebase Console.
3. Используйте `getMessaging()` и `getToken()` для получения FCM-токена.
4. Зарегистрируйте Service Worker для получения фоновых уведомлений.

---

### 2.5 Web Push Notifications — детальная интеграция

#### 2.5.1 Предварительные требования

- Firebase проект с включённым Cloud Messaging
- HTTPS-хост (или `localhost` для разработки) — браузеры требуют безопасного соединения для Push API
- Из Firebase Console → Project Settings → Cloud Messaging скопируйте **VAPID-ключ** (Web Push certificate)

#### 2.5.2 Установка зависимостей

```bash
npm install firebase
# или
yarn add firebase
```

#### 2.5.3 Service Worker (обязательно для фоновых уведомлений)

Создайте файл `public/firebase-messaging-sw.js` в корне публичной директории:

```javascript
// public/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
});

const messaging = firebase.messaging();

// Обработка фоновых уведомлений (приложение свёрнуто или вкладка неактивна)
messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Фоновое уведомление:', payload);

  const { title, body } = payload.notification;
  self.registration.showNotification(title, {
    body,
    icon: '/icon-192.png',
    badge: '/badge-72.png',
    data: payload.data,
  });
});

// Клик по уведомлению — открыть или сфокусировать вкладку приложения
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      if (clientList.length > 0) {
        return clientList[0].focus();
      }
      return clients.openWindow('/');
    })
  );
});
```

> **Важно:** Service Worker должен быть доступен по URL `/firebase-messaging-sw.js` от корня сайта. Файл не должен лежать в поддиректории `/static/` или `/assets/`.

#### 2.5.4 Инициализация Firebase и получение токена

Создайте утилитарный модуль `src/firebase.js`:

```javascript
// src/firebase.js
import { initializeApp } from 'firebase/app';
import { getMessaging, getToken, onMessage, deleteToken } from 'firebase/messaging';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

const VAPID_KEY = import.meta.env.VITE_FIREBASE_VAPID_KEY;
const BFF_URL = import.meta.env.VITE_BFF_URL || 'http://localhost:8084';

const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

/**
 * Запросить разрешение и получить FCM-токен.
 * Возвращает токен или null, если разрешение отклонено.
 */
export async function requestNotificationPermission() {
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') {
    console.warn('Push-уведомления отклонены пользователем');
    return null;
  }

  try {
    const token = await getToken(messaging, {
      vapidKey: VAPID_KEY,
      serviceWorkerRegistration: await navigator.serviceWorker.ready,
    });
    console.log('FCM-токен получен:', token);
    return token;
  } catch (err) {
    console.error('Ошибка получения FCM-токена:', err);
    return null;
  }
}

/**
 * Зарегистрировать FCM-токен на бэкенде.
 */
export async function registerTokenWithBackend(fcmToken, accessToken) {
  const response = await fetch(`${BFF_URL}/api/v1/device-tokens`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`,
      'Idempotency-Key': `token-reg-${fcmToken.slice(-16)}`,
    },
    body: JSON.stringify({ fcmToken, platform: 'WEB' }),
  });

  if (!response.ok) {
    throw new Error(`Ошибка регистрации токена: ${response.status}`);
  }
}

/**
 * Удалить FCM-токен с бэкенда и отозвать его в Firebase.
 */
export async function unregisterToken(fcmToken, accessToken) {
  await fetch(`${BFF_URL}/api/v1/device-tokens`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ fcmToken, platform: 'WEB' }),
  });

  await deleteToken(messaging);
}

/**
 * Подписаться на foreground-уведомления (приложение активно).
 * Callback вызывается при каждом входящем сообщении.
 */
export function onForegroundMessage(callback) {
  return onMessage(messaging, (payload) => {
    console.log('Foreground уведомление:', payload);
    callback(payload);
  });
}

export { messaging };
```

#### 2.5.5 Регистрация Service Worker

Зарегистрируйте SW как можно раньше (например, в `main.js` или `index.js`):

```javascript
// src/main.js
if ('serviceWorker' in navigator) {
  navigator.serviceWorker
    .register('/firebase-messaging-sw.js')
    .then((reg) => console.log('SW зарегистрирован:', reg.scope))
    .catch((err) => console.error('Ошибка регистрации SW:', err));
}
```

#### 2.5.6 React Hook — полная интеграция

```javascript
// src/hooks/usePushNotifications.js
import { useState, useEffect, useCallback, useRef } from 'react';
import {
  requestNotificationPermission,
  registerTokenWithBackend,
  unregisterToken,
  onForegroundMessage,
} from '../firebase';

const MAX_RETRIES = 3;
const RETRY_DELAYS = [5_000, 15_000, 45_000]; // ms

export function usePushNotifications(accessToken) {
  const [permission, setPermission] = useState(Notification.permission);
  const [token, setToken] = useState(null);
  const [lastNotification, setLastNotification] = useState(null);
  const tokenRef = useRef(null);

  // Регистрация с retry-логикой
  const setupPush = useCallback(async () => {
    if (!accessToken) return;

    const fcmToken = await requestNotificationPermission();
    if (!fcmToken) {
      setPermission('denied');
      return;
    }

    setPermission('granted');

    // Retry loop
    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      try {
        await registerTokenWithBackend(fcmToken, accessToken);
        setToken(fcmToken);
        tokenRef.current = fcmToken;
        console.log('Push-токен успешно зарегистрирован');
        return;
      } catch (err) {
        console.warn(`Попытка ${attempt + 1} регистрации токена не удалась:`, err);
        if (attempt < MAX_RETRIES - 1) {
          await new Promise((r) => setTimeout(r, RETRY_DELAYS[attempt]));
        }
      }
    }

    console.error('Не удалось зарегистрировать push-токен после нескольких попыток');
  }, [accessToken]);

  // Инициализация при монтировании
  useEffect(() => {
    if (accessToken && Notification.permission !== 'denied') {
      setupPush();
    }
  }, [accessToken, setupPush]);

  // Foreground-уведомления
  useEffect(() => {
    const unsubscribe = onForegroundMessage((payload) => {
      setLastNotification({
        title: payload.notification?.title,
        body: payload.notification?.body,
        data: payload.data,
        receivedAt: new Date(),
      });
      // Здесь можно показать toast/snackbar вместо системного уведомления
    });

    return () => unsubscribe();
  }, []);

  // Отмена регистрации при логауте
  const logout = useCallback(async () => {
    if (tokenRef.current && accessToken) {
      await unregisterToken(tokenRef.current, accessToken).catch(console.error);
      setToken(null);
      tokenRef.current = null;
    }
  }, [accessToken]);

  return { permission, token, lastNotification, logout, retry: setupPush };
}
```

**Использование хука в компоненте:**

```jsx
// src/App.jsx
import { usePushNotifications } from './hooks/usePushNotifications';
import { useAuth } from './hooks/useAuth';

function App() {
  const { accessToken, handleLogout } = useAuth();
  const { permission, lastNotification, logout } = usePushNotifications(accessToken);

  const onLogout = async () => {
    await logout(); // отменить регистрацию push-токена
    handleLogout();
  };

  return (
    <div>
      {lastNotification && (
        <Toast
          title={lastNotification.title}
          message={lastNotification.body}
        />
      )}
      {/* ... */}
    </div>
  );
}
```

#### 2.5.7 Переменные окружения (.env)

```env
VITE_FIREBASE_API_KEY=your-api-key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:abc123
VITE_FIREBASE_VAPID_KEY=your-vapid-key-from-firebase-console
VITE_BFF_URL=http://localhost:8084
```

> **Получение VAPID-ключа:** Firebase Console → Project Settings → Cloud Messaging → Web Push certificates → Generate key pair.

#### 2.5.8 Ограничения браузеров

| Браузер | Поддержка Web Push | Примечание |
|---------|-------------------|------------|
| Chrome 50+ | ✅ Полная | |
| Firefox 44+ | ✅ Полная | |
| Edge 17+ | ✅ Полная | |
| Safari 16+ | ✅ (macOS/iOS 16.4+) | Требует явного добавления на главный экран на iOS |
| Safari < 16 | ❌ | Не поддерживается |

На **iOS Safari** до версии 16.4 Web Push недоступен. Пользователям iOS Safari до 16.4 можно предложить скачать нативное iOS-приложение.

#### 2.5.9 Проверка разрешения при каждой загрузке

```javascript
// src/utils/checkPushPermission.js
export function getPushPermissionStatus() {
  if (!('Notification' in window)) return 'not-supported';
  if (!('serviceWorker' in navigator)) return 'not-supported';
  return Notification.permission; // 'default' | 'granted' | 'denied'
}

// Показывать кнопку "Включить уведомления" только если статус 'default'
export function shouldPromptForPermission() {
  return getPushPermissionStatus() === 'default';
}
```

---

### 2.6 Circuit Breaker на стороне клиента для регистрации токена

Поскольку бэкенд-сервисы намеренно нестабильны, регистрация FCM-токена может завершиться ошибкой. Необходимо реализовать повторные попытки таким образом, чтобы не блокировать пользовательский интерфейс.

Рекомендуемое поведение:
- Выполнять регистрацию в фоне, не блокируя переход на главный экран.
- При ошибке повторять с экспоненциальным backoff (например, через 5s, 15s, 45s).
- При получении нового FCM-токена от Firebase повторять регистрацию немедленно.
- Не показывать пользователю ошибку регистрации токена — это внутренняя деталь.

---

## 3. Идемпотентность запросов

### 3.1 Когда использовать Idempotency-Key

Заголовок `Idempotency-Key` должен присутствовать во **всех** POST, PUT и PATCH запросах к client-bff и employee-bff, которые изменяют состояние системы. Примеры:

- Создание перевода между счетами
- Оформление кредита
- Изменение настроек пользователя
- Скрытие/отображение счёта

Это гарантирует, что при сетевой ошибке и повторном запросе операция не будет выполнена дважды. Сервер вернёт кешированный ответ первого успешного запроса.

GET и DELETE запросы идемпотентны по определению — дополнительный заголовок не требуется.

### 3.2 Как генерировать ключ

- Генерируйте **UUID v4** для каждого уникального намерения пользователя (одно действие = один ключ).
- Сохраняйте ключ локально (в памяти или SQLite/CoreData) до получения подтверждения от сервера.
- При повторной попытке того же действия **используйте тот же ключ** — именно это обеспечивает идемпотентность.
- После получения успешного ответа ключ можно удалить из локального хранилища.
- Для нового действия (даже аналогичного) генерируйте **новый** ключ.

### 3.3 Пример (iOS Swift)

```swift
import Foundation

func makeIdempotentRequest(url: URL, body: Data, idempotencyKey: UUID = UUID()) async throws -> Data {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(idempotencyKey.uuidString, forHTTPHeaderField: "Idempotency-Key")
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = body

    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}
```

Рекомендуется хранить `idempotencyKey` в модели конкретного действия (например, в объекте `TransferDraft`) и передавать его при каждой попытке отправки этого черновика.

### 3.4 Пример (Android Kotlin)

На Android удобно добавлять заголовок через OkHttp Interceptor:

```kotlin
class IdempotencyInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        // Добавляем заголовок только для POST/PUT/PATCH
        val method = request.method
        if (method != "POST" && method != "PUT" && method != "PATCH") {
            return chain.proceed(request)
        }
        // Ключ должен приходить из вышестоящего слоя (UseCase/ViewModel)
        val idempotencyKey = request.header("Idempotency-Key") ?: return chain.proceed(request)
        val newRequest = request.newBuilder()
            .header("Idempotency-Key", idempotencyKey)
            .build()
        return chain.proceed(newRequest)
    }
}

// Использование в Retrofit/OkHttp:
fun <T> retrofitCall(call: Call<T>, idempotencyKey: String = UUID.randomUUID().toString()): T {
    // Передавайте idempotencyKey через @Header в Retrofit-интерфейсе
    // или через OkHttp Interceptor с ThreadLocal-хранилищем ключа
}
```

### 3.5 Заголовок ответа X-Idempotency-Replayed

Если сервер вернул ответ из кеша (повторный запрос с тем же ключом), в ответе будет присутствовать заголовок:

```
X-Idempotency-Replayed: true
```

Клиент должен обрабатывать такой ответ как успешный — операция была выполнена ранее. Никаких дополнительных действий (повтор, ошибка) не требуется.

---

## 4. Трассировка запросов

### 4.1 Заголовок X-Trace-Id

Заголовок `X-Trace-Id` обеспечивает сквозную трассировку через все сервисы цепочки обработки запроса.

Правила работы с заголовком:
- Если клиент не передаёт `X-Trace-Id`, сервер **генерирует** его автоматически.
- Один и тот же `X-Trace-Id` должен использоваться **во всех запросах в рамках одного пользовательского флоу** (например, весь процесс оформления перевода — один трейс).
- **Ответ всегда содержит** `X-Trace-Id` — его значение можно считать из ответа и использовать в следующих запросах флоу.
- При возникновении ошибки сохраните `X-Trace-Id` для логирования — это позволит разработчикам найти проблемный запрос в мониторинге.

Применение:
- Начало нового флоу (открытие экрана, инициация операции) — **сгенерируйте новый** UUID.
- Повторный запрос в том же флоу — **переиспользуйте** существующий `X-Trace-Id`.
- Каждый отдельный независимый запрос пользователя — **новый** `X-Trace-Id`.

### 4.2 Рекомендуемая реализация (iOS Swift)

```swift
class TracingInterceptor: URLProtocol {
    static var currentTraceId: String = UUID().uuidString

    /// Сбросить трейс — вызывать при начале нового пользовательского флоу
    static func resetTraceId() {
        currentTraceId = UUID().uuidString
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return URLProtocol.property(forKey: "X-Trace-Id-Added", in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
        let traceId = request.value(forHTTPHeaderField: "X-Trace-Id") ?? Self.currentTraceId
        mutableRequest.setValue(traceId, forHTTPHeaderField: "X-Trace-Id")
        URLProtocol.setProperty(true, forKey: "X-Trace-Id-Added", in: mutableRequest)

        let session = URLSession(configuration: .default)
        session.dataTask(with: mutableRequest as URLRequest) { data, response, error in
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }.resume()
    }

    override func stopLoading() {}
}
```

Регистрация в `AppDelegate`:
```swift
URLProtocol.registerClass(TracingInterceptor.self)
```

### 4.3 Рекомендуемая реализация (Android OkHttp)

```kotlin
class TracingInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val traceId = chain.request().header("X-Trace-Id") ?: UUID.randomUUID().toString()
        val request = chain.request().newBuilder()
            .header("X-Trace-Id", traceId)
            .build()
        return chain.proceed(request)
    }
}
```

Добавьте `TracingInterceptor` в `OkHttpClient`:
```kotlin
val client = OkHttpClient.Builder()
    .addInterceptor(TracingInterceptor())
    .build()
```

Для управления трейсом в рамках пользовательских флоу используйте `ThreadLocal` или передавайте `traceId` явно через ViewModel/UseCase.

---

## 5. Мониторинг со стороны клиента

### 5.1 API мониторинга (открытый, без аутентификации)

Сервис мониторинга доступен без авторизации. Базовый URL зависит от среды (см. раздел 8.1).

**Отправить метрику:**
```http
POST http://localhost:8086/api/v1/metrics
Content-Type: application/json

{
  "type": "REQUEST_TRACE",
  "service": "ios-client",
  "traceId": "550e8400-e29b-41d4-a716-446655440000",
  "recordedAt": "2026-04-11T12:00:00",
  "durationMs": 250,
  "method": "POST",
  "path": "/api/v1/transfers",
  "statusCode": 200,
  "errorMessage": null,
  "metadata": "{\"userId\": 123}"
}
```

**Описание полей:**

| Поле | Тип | Обязательное | Описание |
|------|-----|:------------:|---------|
| `type` | string | да | Тип метрики: `REQUEST_TRACE`, `ERROR`, `CUSTOM` |
| `service` | string | да | Имя сервиса/приложения (`ios-client`, `android-client`, `web-client`) |
| `traceId` | string (UUID) | да | Идентификатор трейса |
| `recordedAt` | string (ISO datetime) | нет | Время события; если не указано, сервер использует текущее время |
| `durationMs` | integer | нет | Время выполнения запроса в миллисекундах |
| `method` | string | нет | HTTP-метод (`GET`, `POST`, и т.д.) |
| `path` | string | нет | Путь запроса (`/api/v1/transfers`) |
| `statusCode` | integer | нет | HTTP-код ответа |
| `errorMessage` | string | нет | Описание ошибки (для типов `ERROR` и `CUSTOM`) |
| `metadata` | string (JSON) | нет | Произвольные дополнительные данные в виде JSON-строки |

**Типы метрик:**

- `REQUEST_TRACE` — успешный HTTP-запрос с временем выполнения. Используется для всех запросов к бэкенду.
- `ERROR` — ошибка: HTTP 5xx или сетевая ошибка (таймаут, нет соединения).
- `CUSTOM` — произвольное событие: краш приложения, открытие Circuit Breaker, просмотр экрана, и т.д.

### 5.2 Что отправлять из мобильного приложения

Рекомендуется отправлять следующие события:

| Событие | Тип | Когда |
|---------|-----|-------|
| Каждый HTTP-запрос к бэкенду | `REQUEST_TRACE` | После получения ответа |
| HTTP 5xx или сетевая ошибка | `ERROR` | При получении ошибки |
| Открытие Circuit Breaker | `CUSTOM` | При переходе CB в состояние Open |
| Краш приложения | `CUSTOM` | При перехвате необработанного исключения |

Метрики отправляются **в фоне** — они не должны блокировать пользовательский интерфейс и не должны показывать пользователю ошибки в случае недоступности monitoring-service.

### 5.3 Пример реализации мониторинга (iOS Swift)

```swift
class MonitoringService {
    static let shared = MonitoringService()
    private let baseURL = URL(string: "http://localhost:8086")!
    private let serviceName = "ios-client"

    func trackRequest(
        traceId: String,
        method: String,
        path: String,
        statusCode: Int,
        durationMs: Int,
        error: String? = nil
    ) {
        let payload: [String: Any] = [
            "type": statusCode >= 500 ? "ERROR" : "REQUEST_TRACE",
            "service": serviceName,
            "traceId": traceId,
            "durationMs": durationMs,
            "method": method,
            "path": path,
            "statusCode": statusCode,
            "errorMessage": error as Any
        ]

        // Fire and forget — не блокировать UI
        Task {
            var request = URLRequest(url: baseURL.appendingPathComponent("/api/v1/metrics"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            try? await URLSession.shared.data(for: request)
        }
    }

    func trackCustomEvent(name: String, metadata: [String: Any] = [:]) {
        var meta = metadata
        meta["event"] = name
        let metaJson = (try? String(data: JSONSerialization.data(withJSONObject: meta), encoding: .utf8)) ?? "{}"

        let payload: [String: Any] = [
            "type": "CUSTOM",
            "service": serviceName,
            "traceId": UUID().uuidString,
            "metadata": metaJson
        ]
        Task {
            var request = URLRequest(url: baseURL.appendingPathComponent("/api/v1/metrics"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            try? await URLSession.shared.data(for: request)
        }
    }
}
```

Использование в сетевом слое:
```swift
let start = Date()
do {
    let data = try await networkClient.perform(request)
    let durationMs = Int(Date().timeIntervalSince(start) * 1000)
    MonitoringService.shared.trackRequest(
        traceId: currentTraceId,
        method: request.httpMethod ?? "GET",
        path: request.url?.path ?? "",
        statusCode: 200,
        durationMs: durationMs
    )
} catch let error as HTTPError {
    let durationMs = Int(Date().timeIntervalSince(start) * 1000)
    MonitoringService.shared.trackRequest(
        traceId: currentTraceId,
        method: request.httpMethod ?? "GET",
        path: request.url?.path ?? "",
        statusCode: error.statusCode,
        durationMs: durationMs,
        error: error.localizedDescription
    )
    throw error
}
```

### 5.4 Пример реализации мониторинга (Android Kotlin)

```kotlin
object MonitoringService {
    private val client = OkHttpClient()
    private const val BASE_URL = "http://10.0.2.2:8086" // адрес для Android Emulator
    private const val SERVICE_NAME = "android-client"

    fun trackRequest(
        traceId: String,
        method: String,
        path: String,
        statusCode: Int,
        durationMs: Long,
        error: String? = null
    ) {
        val payload = JSONObject().apply {
            put("type", if (statusCode >= 500) "ERROR" else "REQUEST_TRACE")
            put("service", SERVICE_NAME)
            put("traceId", traceId)
            put("durationMs", durationMs)
            put("method", method)
            put("path", path)
            put("statusCode", statusCode)
            error?.let { put("errorMessage", it) }
        }

        // Fire and forget в background coroutine
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val body = payload.toString().toRequestBody("application/json".toMediaType())
                val request = Request.Builder()
                    .url("$BASE_URL/api/v1/metrics")
                    .post(body)
                    .build()
                client.newCall(request).execute().close()
            } catch (e: Exception) {
                // Игнорируем ошибки мониторинга — не мешаем основному флоу
            }
        }
    }

    fun trackCustomEvent(name: String, metadata: Map<String, Any> = emptyMap()) {
        val meta = JSONObject(metadata + mapOf("event" to name))
        val payload = JSONObject().apply {
            put("type", "CUSTOM")
            put("service", SERVICE_NAME)
            put("traceId", UUID.randomUUID().toString())
            put("metadata", meta.toString())
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val body = payload.toString().toRequestBody("application/json".toMediaType())
                val request = Request.Builder()
                    .url("$BASE_URL/api/v1/metrics")
                    .post(body)
                    .build()
                client.newCall(request).execute().close()
            } catch (e: Exception) {
                // Игнорируем
            }
        }
    }
}
```

Интеграция через OkHttp Interceptor:
```kotlin
class MonitoringInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val traceId = request.header("X-Trace-Id") ?: UUID.randomUUID().toString()
        val startTime = System.currentTimeMillis()

        return try {
            val response = chain.proceed(request)
            val durationMs = System.currentTimeMillis() - startTime
            MonitoringService.trackRequest(
                traceId = traceId,
                method = request.method,
                path = request.url.encodedPath,
                statusCode = response.code,
                durationMs = durationMs
            )
            response
        } catch (e: IOException) {
            val durationMs = System.currentTimeMillis() - startTime
            MonitoringService.trackRequest(
                traceId = traceId,
                method = request.method,
                path = request.url.encodedPath,
                statusCode = 0,
                durationMs = durationMs,
                error = e.message
            )
            throw e
        }
    }
}
```

### 5.5 Веб-дашборд мониторинга

Доступен по адресу: `http://localhost:8086/dashboard`

Возможности дашборда:
- Столбчатая диаграмма процента ошибок по каждому сервису.
- Временная шкала запросов по каждому сервису.
- Сводная таблица: общее количество запросов, ошибок, среднее время / p95 latency.
- Автообновление каждые 30 секунд.
- Фильтрация по сервису и временному диапазону (1 час, 6 часов, 24 часа).

Дашборд полезен для:
- Наблюдения за поведением клиентских приложений в реальном времени.
- Отладки проблем с Circuit Breaker.
- Анализа распределения ошибок по времени (в том числе эффекта ChaosFilter на чётных минутах).

---

## 6. Circuit Breaker на стороне клиента

### 6.1 Зачем нужен Circuit Breaker в клиенте

Сервисы core-service, user-service и credit-service намеренно возвращают ошибки в 30-70% случаев (ChaosFilter). BFF-сервисы имеют собственный Circuit Breaker на базе Resilience4j, однако это не означает, что клиент полностью защищён:

- BFF Circuit Breaker может быть открыт — тогда BFF сам вернёт 503.
- Сетевые ошибки (таймаут, обрыв соединения) не обрабатываются BFF.
- Повторные запросы без backoff перегружают систему.

Клиентский Circuit Breaker предотвращает каскадные сбои в UX и снижает нагрузку на бэкенд в периоды нестабильности.

### 6.2 Рекомендуемые параметры

| Параметр | Значение | Описание |
|----------|----------|---------|
| Порог открытия | 5 последовательных ошибок или 70% ошибок из 10 запросов | |
| Время в состоянии Open | 30 секунд | После истечения переходит в Half-Open |
| Half-Open | 1 пробный запрос | Если успешен — закрывается, если нет — снова открывается |

Разные эндпоинты могут иметь разные Circuit Breaker'ы (например, для переводов и для чтения баланса).

### 6.3 Пример реализации (iOS Swift)

```swift
class CircuitBreaker {
    enum State { case closed, open, halfOpen }

    private var state: State = .closed
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let threshold = 5
    private let timeout: TimeInterval = 30

    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        switch state {
        case .open:
            guard let lastFailure = lastFailureTime,
                  Date().timeIntervalSince(lastFailure) > timeout else {
                throw CircuitBreakerError.open
            }
            state = .halfOpen
            fallthrough
        case .closed, .halfOpen:
            do {
                let result = try await operation()
                onSuccess()
                return result
            } catch {
                onFailure()
                throw error
            }
        }
    }

    private func onSuccess() {
        failureCount = 0
        state = .closed
    }

    private func onFailure() {
        failureCount += 1
        lastFailureTime = Date()
        if failureCount >= threshold {
            state = .open
            MonitoringService.shared.trackCustomEvent(
                name: "circuit_breaker_open",
                metadata: ["threshold": threshold]
            )
        }
    }
}

enum CircuitBreakerError: Error {
    case open
}
```

Использование:
```swift
let circuitBreaker = CircuitBreaker()

do {
    let transfer = try await circuitBreaker.execute {
        try await transferService.createTransfer(request)
    }
} catch CircuitBreakerError.open {
    // Показать пользователю сообщение: "Сервис временно недоступен, попробуйте позже"
} catch {
    // Обработать другие ошибки
}
```

### 6.4 Retry с экспоненциальным backoff (iOS)

```swift
func withRetry<T>(
    maxAttempts: Int = 3,
    baseDelay: TimeInterval = 0.5,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    for attempt in 0..<maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            if attempt < maxAttempts - 1 {
                // backoff: 500ms → 1s → 2s
                let delay = baseDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    throw lastError!
}
```

Совместное использование Retry и Circuit Breaker:
```swift
let result = try await circuitBreaker.execute {
    try await withRetry(maxAttempts: 3) {
        try await apiClient.createTransfer(request)
    }
}
```

### 6.5 Retry с экспоненциальным backoff (Android Kotlin)

```kotlin
suspend fun <T> withRetry(
    maxAttempts: Int = 3,
    baseDelayMs: Long = 500L,
    operation: suspend () -> T
): T {
    var lastException: Exception? = null
    repeat(maxAttempts) { attempt ->
        try {
            return operation()
        } catch (e: Exception) {
            lastException = e
            if (attempt < maxAttempts - 1) {
                val delayMs = baseDelayMs * (1L shl attempt) // 500ms → 1s → 2s
                delay(delayMs)
            }
        }
    }
    throw lastException!!
}
```

---

## 7. Интеграция с WebSocket (STOMP)

### 7.1 Текущая реализация

Real-time обновления операций доступны через WebSocket с протоколом STOMP:

- **URL подключения:** `ws://localhost:8084/ws` (через client-bff)
- **Топик подписки:** `/topic/accounts/{accountId}/operations`
- **Аутентификация:** передайте access token как параметр подключения или через STOMP-заголовок

Пример подключения (iOS, библиотека StompClientLib):
```swift
let url = URL(string: "ws://localhost:8084/ws/websocket")!
let token = "Bearer \(accessToken)"
stompClient.openSocketWithURLRequest(
    NSURLRequest(url: url),
    delegate: self,
    connectionHeaders: ["Authorization": token]
)
// После подключения:
stompClient.subscribe(destination: "/topic/accounts/\(accountId)/operations")
```

### 7.2 Рекомендации

**Переподключение при разрыве:**
- Реализуйте автоматическое переподключение с экспоненциальным backoff (1s → 2s → 4s → ... → 60s максимум).
- Ограничьте количество попыток или сбрасывайте счётчик при успешном подключении.

**Синхронизация при отключении:**
- Если пришло push-уведомление о новой операции, пока WebSocket был отключён, выполните REST-запрос для загрузки последних операций.
- Не полагайтесь только на WebSocket — считайте его оптимизацией, а не основным механизмом доставки данных.

**Мониторинг:**
- При разрыве WebSocket-соединения отправьте `CUSTOM`-событие в monitoring-service:
  ```swift
  MonitoringService.shared.trackCustomEvent(
      name: "websocket_disconnected",
      metadata: ["accountId": accountId, "reason": reason]
  )
  ```
- При восстановлении соединения также отправьте событие `websocket_reconnected`.

**Обработка ошибок аутентификации:**
- Если WebSocket-соединение закрывается с кодом 401/403, выполните обновление access token и переподключитесь.
- Не переподключайтесь бесконечно при ошибках аутентификации — это признак истёкшей сессии.

---

## 8. Настройка окружений

### 8.1 Адреса сервисов

| Среда | client-bff | employee-bff | monitoring-service |
|-------|-----------|--------------|-------------------|
| Локально | `http://localhost:8084` | `http://localhost:8085` | `http://localhost:8086` |
| Docker (внутри контейнера) | `http://client-bff:8084` | `http://employee-bff:8085` | `http://monitoring-service:8086` |
| Android Emulator | `http://10.0.2.2:8084` | `http://10.0.2.2:8085` | `http://10.0.2.2:8086` |
| iOS Simulator | `http://localhost:8084` | `http://localhost:8085` | `http://localhost:8086` |

Рекомендуется выносить базовые URL в конфигурационный файл (`Config.xcconfig` для iOS, `BuildConfig` для Android, `.env` для Web), а не хардкодить в исходном коде.

### 8.2 Firebase настройка бэкенда

Для работы push-уведомлений необходимо настроить Firebase Service Account на стороне бэкенда перед запуском BFF-сервисов.

**Локальный запуск:**
```bash
export FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/firebase-service-account.json
cd backend && ./gradlew :client-bff:bootRun
```

**Docker Compose:**
```yaml
services:
  client-bff:
    environment:
      FIREBASE_SERVICE_ACCOUNT_PATH: /secrets/firebase-service-account.json
    volumes:
      - ./firebase-service-account.json:/secrets/firebase-service-account.json:ro

  employee-bff:
    environment:
      FIREBASE_SERVICE_ACCOUNT_PATH: /secrets/firebase-service-account.json
    volumes:
      - ./firebase-service-account.json:/secrets/firebase-service-account.json:ro
```

Если переменная окружения не задана, бэкенд **молча пропускает** отправку push-уведомлений. WebSocket и REST API продолжают работать в штатном режиме. Это позволяет запускать систему в разработке без настроенного Firebase.

### 8.3 Проверка работы push-уведомлений

1. Убедитесь, что `FIREBASE_SERVICE_ACCOUNT_PATH` указывает на валидный файл сервисного аккаунта.
2. Зарегистрируйте FCM-токен через `POST /api/v1/device-tokens`.
3. Выполните операцию по счёту (например, через employee-bff).
4. Убедитесь, что уведомление пришло на устройство.

Если уведомление не приходит:
- Проверьте логи BFF-сервиса на наличие ошибок Firebase.
- Убедитесь, что устройство зарегистрировано с правильным `accountId`.
- Убедитесь, что FCM-токен актуален (токены обновляются Firebase SDK).

---

## 9. Checklist для разработчиков мобилки/фронта

Перед сдачей функциональности убедитесь, что выполнены следующие пункты:

### Аутентификация и FCM
- [ ] Зарегистрировать FCM-токен после успешного логина (`POST /api/v1/device-tokens`)
- [ ] Обновлять FCM-токен при получении нового от Firebase SDK
- [ ] Отменить регистрацию FCM-токена при логауте (`DELETE /api/v1/device-tokens`)
- [ ] Настроить `GoogleService-Info.plist` (iOS) или `google-services.json` (Android)

### Заголовки запросов
- [ ] Добавить `Idempotency-Key` (UUID v4) ко всем POST/PUT/PATCH запросам
- [ ] Добавить `X-Trace-Id` к каждому запросу (генерировать новый при начале флоу, переиспользовать в рамках одного флоу)
- [ ] Считывать `X-Trace-Id` из ответа и сохранять для логирования ошибок
- [ ] Корректно обрабатывать ответ с заголовком `X-Idempotency-Replayed: true`

### Отказоустойчивость
- [ ] Реализовать Retry с экспоненциальным backoff (3 попытки: 500ms → 1s → 2s)
- [ ] Реализовать Circuit Breaker (открывается при 5 последовательных ошибках или 70% ошибок, таймаут 30 секунд)
- [ ] Регистрация FCM-токена выполняется в фоне, не блокирует UX

### Мониторинг
- [ ] Отправлять метрики `REQUEST_TRACE` для каждого HTTP-запроса к бэкенду
- [ ] Отправлять метрики `ERROR` для HTTP 5xx и сетевых ошибок
- [ ] Отправлять `CUSTOM`-событие при открытии Circuit Breaker
- [ ] Отправлять `CUSTOM`-событие при крашах приложения
- [ ] Метрики отправляются в фоне, ошибки отправки игнорируются

### WebSocket
- [ ] Реализовать переподключение с экспоненциальным backoff при разрыве WebSocket
- [ ] При отключении WebSocket и получении push-уведомления — синхронизировать операции через REST
- [ ] Логировать события подключения/отключения WebSocket в monitoring-service

### Конфигурация
- [ ] Базовые URL вынесены в конфигурационный файл (не хардкодить)
- [ ] Настроены разные URL для локальной разработки, эмулятора и продакшена
- [ ] Настроены таймауты HTTP-клиента (рекомендуется: connect 10s, read 30s, write 30s)
