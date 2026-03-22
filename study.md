# Bank — Техническое описание системы

Документ описывает архитектуру, безопасность, схемы взаимодействий и принципы надёжности бэкенда банковского приложения. Предназначен для разработчиков, впервые погружающихся в проект.

---

## Содержание

1. [Обзор архитектуры](#1-обзор-архитектуры)
2. [Инфраструктура](#2-инфраструктура)
3. [OAuth2 и безопасность](#3-oauth2-и-безопасность)
4. [Сервисы — подробно](#4-сервисы--подробно)
5. [Межсервисное взаимодействие](#5-межсервисное-взаимодействие)
6. [Kafka и асинхронность](#6-kafka-и-асинхронность)
7. [Transactional Outbox](#7-transactional-outbox)
8. [WebSocket и real-time уведомления](#8-websocket-и-real-time-уведомления)
9. [Базы данных](#9-базы-данных)
10. [Бизнес-процессы](#10-бизнес-процессы)
11. [Надёжность системы](#11-надёжность-системы)
12. [Ошибки и их обработка](#12-ошибки-и-их-обработка)

---

## 1. Обзор архитектуры

Система построена как **Java-монорепо** с шестью микросервисами, объединёнными в единое приложение через общий Gradle multi-module build. Каждый сервис — это отдельный Spring Boot процесс со своей базой данных.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        КЛИЕНТСКИЕ ПРИЛОЖЕНИЯ                        │
│              iOS App (Swift)          Employee Web App               │
└────────────────┬────────────────────────────┬───────────────────────┘
                 │                            │
         HTTPS + JWT                   HTTPS + JWT
                 │                            │
┌────────────────▼──────────┐   ┌─────────────▼─────────────┐
│      client-bff :8084     │   │    employee-bff :8085      │
│  BFF для клиентского      │   │  BFF для сотрудников       │
│  приложения               │   │                            │
│  • OAuth2 Resource Server │   │  • OAuth2 Resource Server  │
│  • Ownership checks       │   │  • Proxy to backends       │
│  • User settings (Redis)  │   │  • User settings (Redis)   │
└──────┬──────────────┬─────┘   └──────┬──────────────┬──────┘
       │              │                │              │
       │       ┌──────▼────────────────▼──────┐      │
       │       │      Kafka Consumer           │      │
       │       │  bank.operation-notifications │      │
       │       └──────────────────────────────┘      │
       │                                             │
       │  REST (RestClient)                          │  REST (RestClient)
       │                                             │
┌──────▼──────────┐  ┌─────────────────┐  ┌─────────▼───────────┐
│  core-service   │  │  user-service   │  │   credit-service    │
│     :8080       │  │     :8082       │  │      :8083          │
│                 │  │                 │  │                     │
│  • Accounts     │  │  • Users        │  │  • Credits          │
│  • Operations   │  │  • Roles        │  │  • Tariffs          │
│  • Transfers    │  │                 │  │  • Payments         │
│  • Kafka prod.  │  │                 │  │  • Scheduler        │
│  • Outbox       │  │                 │  │  • CoreClient       │
└──────┬──────────┘  └─────────────────┘  └─────────────────────┘
       │
  Kafka Producer
  (bank.operations)
       │
┌──────▼──────────┐
│  Kafka Consumer │
│  (core-service) │
│  bank.operations│
└─────────────────┘

┌─────────────────────────────────────────┐
│            auth-service :8081           │
│                                         │
│  • OAuth2 Authorization Server          │
│  • Login form (HTML)                    │
│  • JWT issuer (RSA 2048)                │
│  • Manages AuthUsers                    │
│  • Calls user-service on register       │
└─────────────────────────────────────────┘
```

### Принципы дизайна

| Принцип | Реализация |
|---------|-----------|
| **Service-per-database** | Каждый сервис имеет свою PostgreSQL БД, прямой доступ к чужой БД запрещён |
| **BFF pattern** | client-bff и employee-bff — серверная часть конкретных клиентов, хранят UI-настройки |
| **Event-driven** | Операции по счетам проходят через Kafka, гарантируя at-least-once доставку |
| **OAuth2 SSO** | Единая точка входа через auth-service, пароль вводится только там |
| **Idempotency** | Каждая операция имеет UUID-ключ идемпотентности, дубликаты пропускаются |

---

## 2. Инфраструктура

### Порты сервисов

| Сервис | Порт | БД порт | БД имя |
|--------|------|---------|--------|
| core-service | 8080 | 5438 | bank_core |
| auth-service | 8081 | 5433 | bank_auth |
| user-service | 8082 | 5434 | bank_user |
| credit-service | 8083 | 5435 | bank_credit |
| client-bff | 8084 | 5436 | bank_client_bff |
| employee-bff | 8085 | 5437 | bank_employee_bff |

### Брокер и кеш

| Компонент | Адрес | Назначение |
|-----------|-------|-----------|
| Kafka (внешний) | `localhost:9094` | Для локальной разработки |
| Kafka (Docker) | `kafka:9092` | Внутри Docker сети |
| Redis | `localhost:6379` | Сессии BFF-сервисов, кеш курсов валют |

Kafka работает в **KRaft mode** (без ZooKeeper), образ `apache/kafka:3.9.0`.

---

## 3. OAuth2 и безопасность

### 3.1 Общая схема аутентификации

Система использует **OAuth 2.0 Authorization Code Flow с PKCE**. Пароль пользователя видит **только auth-service** — это принципиальное требование безопасности.

```
iOS App / Web App
      │
      │  1. Открывает браузер/WebView на auth-service
      ▼
auth-service :8081  ←──── Пользователь вводит логин/пароль ЗДЕСЬ
      │
      │  2. Выдаёт Authorization Code
      ▼
BFF (client-bff или employee-bff)
      │
      │  3. Обменивает Code на Access Token (JWT) + Refresh Token
      ▼
iOS App / Web App  ←──── Получает JWT, хранит на устройстве
      │
      │  4. Все последующие запросы: Authorization: Bearer {jwt}
      ▼
BFF  ──── проверяет JWT ──── делает запросы к backend-сервисам
```

### 3.2 Auth-Service как Authorization Server

**Зарегистрированные OAuth2-клиенты:**

```
client-bff:
  clientId:     client-bff
  secret:       client-bff-secret (bcrypt)
  grantTypes:   AUTHORIZATION_CODE, REFRESH_TOKEN
  redirectUris: http://localhost:8084/login/oauth2/code/auth-service
                http://localhost:3000/callback
                bankapp://callback          ← для iOS Universal Link
  scopes:       openid, profile, accounts.read, accounts.write,
                credits.read, credits.write
  PKCE:         обязателен
  tokenTTL:     access = 1 час, refresh = 30 дней

employee-bff:
  clientId:     employee-bff
  secret:       employee-bff-secret
  redirectUris: http://localhost:8085/login/oauth2/code/auth-service
                http://localhost:3001/callback
                bankemployee://callback
  scopes:       openid, profile, admin
  PKCE:         обязателен
  tokenTTL:     access = 1 час, refresh = 30 дней
```

**JWT-токен** подписывается RSA 2048-bit ключом. Содержит:
- `sub`: email пользователя (используется как username)
- `roles`: список ролей (`CLIENT`, `EMPLOYEE`, `ADMIN`, `MANAGER`)
- `iss`: `http://localhost:8081`
- `exp`: время истечения

**Как auth-service знает роли пользователя:** При выдаче JWT он вызывает `user-service` через REST, получает список ролей и добавляет их в token claims через кастомный `OAuth2TokenCustomizer`.

### 3.3 AuthUser vs User

В системе есть **два разных пользовательских хранилища**:

| | auth-service | user-service |
|-|-------------|-------------|
| Таблица | `auth_users` | `users` |
| Хранит | email + bcrypt-пароль + enabled | email + имя + телефон + роли + blocked |
| Цель | Аутентификация (SSO) | Бизнес-данные профиля |
| Синхронизация | При регистрации auth-service вызывает user-service |

Оба хранят `email` как общий идентификатор. Никакого общего ключа нет — привязка только по email.

### 3.4 Регистрация пользователя

```
Client → POST /api/v1/auth/register
         {email, password, firstName, lastName, phone, roles}
              │
              ▼
         auth-service:
           1. Проверяет email уникальность в auth_users
           2. Сохраняет AuthUser (bcrypt-хеш пароля)
           3. Вызывает POST /api/v1/users → user-service
              {email, firstName, lastName, phone, roles}
           4. user-service создаёт User с ролями
           5. Возвращает {message: "Регистрация успешна"}
```

Если `user-service` недоступен — регистрация упадёт. Отдельная saga/компенсация не реализована.

### 3.5 Resource Server (BFF-сервисы)

Оба BFF настроены как **OAuth2 Resource Server**:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8081
```

Spring автоматически:
1. Загружает JWKS (публичный ключ RSA) с `http://localhost:8081/.well-known/jwks.json`
2. Верифицирует подпись каждого входящего JWT
3. Проверяет срок действия (`exp`)

Роли извлекаются кастомным `RolesClaimConverter`:
- Читает claim `roles` из JWT
- Добавляет префикс `ROLE_` → `ROLE_CLIENT`, `ROLE_ADMIN` и т.д.
- Spring Security видит их как стандартные `GrantedAuthority`

### 3.6 Публичные и защищённые эндпоинты

**auth-service:**
```
Публичные:  /api/v1/auth/register, /login, /css/**, /js/**,
            /swagger-ui/**, /v3/api-docs/**
Остальное:  требует JWT
```

**client-bff / employee-bff:**
```
Публичные:  /ws/**  (WebSocket подключение без JWT — STOMP-фрейм несёт токен)
Остальное:  требует JWT
```

**core-service, user-service, credit-service:**
Не настроены как Resource Server — **доступны только из внутренней сети**. Нет прямого доступа извне.

### 3.7 CORS

BFF-сервисы и auth-service разрешают `*` origins с `credentials: true`. Это допустимо в dev-окружении; для prod нужен whitelist.

---

## 4. Сервисы — подробно

### 4.1 auth-service (порт 8081)

**Единственный контроллер:** `AuthController`

```
POST /api/v1/auth/register
  Body:  { email, password, firstName, lastName, phone, roles? }
  200:   { message: "Регистрация успешна" }
  409:   EmailAlreadyExistsException

GET /userinfo  (OAuth2 standard endpoint)
  Header: Authorization: Bearer {jwt}
  200:   { sub: email, email: email }
```

**Логин** происходит через стандартный OAuth2 flow — не через REST API. Пользователь перенаправляется на `GET /login` (HTML-форма Spring Security), вводит email/пароль, и auth-service через `CustomUserDetailsService` проверяет пароль:

```
CustomUserDetailsService.loadUserByUsername(email):
  1. GET /api/v1/users/by-email?email={email} → user-service
  2. Проверяет blocked=false
  3. Получает роли
  4. Ищет AuthUser в auth_users по email
  5. Возвращает UserDetails с паролем + GrantedAuthorities
```

Пароль сравнивает Spring Security через `BCryptPasswordEncoder`. Auth-service **не хранит** бизнес-роли у себя — берёт их из user-service при каждой аутентификации.

---

### 4.2 user-service (порт 8082)

Хранит профили пользователей. Вызывается auth-service и BFF-сервисами.

**Эндпоинты:**

```
POST   /api/v1/users                   → 201 UserResponse
GET    /api/v1/users                   → List<UserResponse>
GET    /api/v1/users/{id}              → UserResponse
GET    /api/v1/users/by-email?email=   → UserResponse       ← критичный для SSO
PUT    /api/v1/users/{id}              → UserResponse
PATCH  /api/v1/users/{id}/roles        → UserResponse
PATCH  /api/v1/users/{id}/block        → UserResponse
PATCH  /api/v1/users/{id}/unblock      → UserResponse
GET    /api/v1/users/roles             → List<Role>
```

**UserResponse:**
```json
{
  "id": 1,
  "email": "alice@example.com",
  "firstName": "Alice",
  "lastName": "Smith",
  "phone": "+79001234567",
  "roles": ["CLIENT"],
  "blocked": false,
  "createdAt": "2024-01-01T00:00:00",
  "updatedAt": "2024-01-01T00:00:00"
}
```

**Роли:** `CLIENT`, `ADMIN`, `EMPLOYEE`, `MANAGER`

Блокировка пользователя (`blocked=true`) — только через PATCH. Заблокированный пользователь не сможет войти (проверяется в `CustomUserDetailsService`).

---

### 4.3 core-service (порт 8080)

Центральный сервис — управляет счетами и операциями.

**Эндпоинты счетов:**

```
POST   /api/v1/accounts                         → 201 AccountResponse
GET    /api/v1/accounts?userId={id}             → List<AccountResponse>
GET    /api/v1/accounts/{id}                    → AccountResponse
DELETE /api/v1/accounts/{id}                    → 204  (только если balance=0)

POST   /api/v1/accounts/{id}/deposit            → 202  (async)
POST   /api/v1/accounts/{id}/withdraw           → 202  (async)
GET    /api/v1/accounts/{id}/operations?page=0&size=20 → Page<OperationResponse>

POST   /api/v1/transfers                        → 202  (async)
```

**Мастер-счета (системные):**
```
GET    /api/v1/master-account                   → List<AccountResponse>
GET    /api/v1/master-account?currency=RUB      → AccountResponse
POST   /api/v1/master-account/transfer          → 202  (async)
```

Мастер-счета — по одному на каждую валюту (RUB, USD, EUR). Через них credit-service зачисляет кредитные средства на счёт клиента.

**Типы аккаунтов и операций:**

```
AccountType:   PERSONAL (пользовательский), MASTER (системный)
Currency:      RUB, USD, EUR
OperationType: DEPOSIT, WITHDRAWAL, TRANSFER_IN, TRANSFER_OUT
```

**Оптимистичная блокировка:**
Поле `version` на `Account` (JPA `@Version`). Если два потока одновременно читают и изменяют один счёт — один из них получит `OptimisticLockingFailureException`.

**Пессимистичная блокировка для трансферов:**
При обработке перевода через Kafka-консьюмер оба счёта блокируются с `SELECT FOR UPDATE` в строгом порядке (по возрастанию ID), чтобы исключить deadlock:

```java
if (fromId < toId) {
    fromAccount = lockAccount(fromId);  // SELECT FOR UPDATE
    toAccount   = lockAccount(toId);
} else {
    toAccount   = lockAccount(toId);
    fromAccount = lockAccount(fromId);
}
```

---

### 4.4 credit-service (порт 8083)

Управляет кредитами, тарифами и платежами.

**Эндпоинты:**

```
GET    /api/v1/tariffs                          → List<TariffResponse>
POST   /api/v1/tariffs                          → 201 TariffResponse

POST   /api/v1/credits                          → 201 CreditResponse
GET    /api/v1/credits?userId={id}              → List<CreditResponse>
GET    /api/v1/credits/{id}                     → CreditResponse
GET    /api/v1/credits/{id}/payments            → List<PaymentResponse>
POST   /api/v1/credits/{id}/repay               → CreditResponse

GET    /api/v1/users/{id}/credit-rating         → CreditRatingResponse
```

**Расчёт ежедневного платежа (аннуитет):**

```
dailyRate    = annualRate / (365 * 24 * 60)   ← минутная ставка
dailyPayment = principal * dailyRate / (1 - (1 + dailyRate)^(-termDays))

Если rate = 0:
dailyPayment = principal / termDays
```

При создании кредита генерируется полный **график платежей** (`payments`) — по одному на каждый день срока.

**Начисление процентов (per-minute accrual):**

Проценты начисляются поминутно, но применяются при досрочном или плановом погашении:

```
minuteRate       = annualRate / (365 * 24 * 60)
minutesElapsed   = Duration.between(lastAccrualAt, now()).toMinutes()
accruedInterest  = remaining * ((1 + minuteRate)^minutesElapsed - 1)
```

**Credit Rating (кредитный рейтинг):**

```
base  = 850
score = base - overduePayments * 50 + closedCredits * 10
score = clamp(score, 300, 850)

Грейды:
  EXCELLENT  score >= 750
  GOOD       score >= 650
  FAIR       score >= 550
  POOR       score >= 450
  BAD        score < 450
```

**PaymentScheduler — ежедневный планировщик:**

```
Cron: 0 0 0 * * *  (каждую ночь в 00:00)

Алгоритм:
1. Найти все PENDING payments с dueDate < now()
2. Для каждого:
   a. POST /api/v1/accounts/{accountId}/withdraw → core-service
   b. Успех → payment.status = PAID, credit.remaining -= amount
   c. Ошибка (InsufficientFunds) → payment.status = OVERDUE,
                                    credit.status = OVERDUE
3. Если credit.remaining <= 0 → credit.status = CLOSED
```

---

### 4.5 client-bff (порт 8084)

BFF для iOS-приложения. Это **не тонкий прокси** — у него есть собственная бизнес-логика: проверка прав доступа и хранение UI-настроек.

**Ключевые компоненты:**

```
UserResolverService      — извлекает userId из JWT (по email → user-service)
ResourceOwnershipService — проверяет, что ресурс принадлежит текущему пользователю
SettingsService          — хранит тему и скрытые счета в локальной БД
```

**Как работает проверка владения:**

```
GET /api/v1/accounts/{id}  [Authorization: Bearer {jwt}]
      │
      ▼
1. Извлечь email из JWT.subject
2. GET /api/v1/users/by-email?email={email} → user-service → userId
3. GET /api/v1/accounts/{id} → core-service → account.userId
4. Если account.userId != userId → 403 ResourceAccessDeniedException
5. Иначе → вернуть AccountResponse клиенту
```

**Эндпоинты (зеркало core/credit с ownership check):**

```
GET    /api/v1/accounts            — фильтрует по userId текущего пользователя
GET    /api/v1/accounts/{id}       — ownership check
POST   /api/v1/accounts            — инжектирует userId из JWT в body
DELETE /api/v1/accounts/{id}       — ownership check
POST   /api/v1/accounts/{id}/deposit    — ownership check
POST   /api/v1/accounts/{id}/withdraw   — ownership check
GET    /api/v1/accounts/{id}/operations — ownership check
POST   /api/v1/transfers           — ownership check fromAccountId
GET    /api/v1/credits             — фильтрует по userId
GET    /api/v1/credits/{id}        — ownership check
POST   /api/v1/credits             — ownership check accountId
GET    /api/v1/credits/{id}/payments    — ownership check
POST   /api/v1/credits/{id}/repay       — ownership check

GET    /api/v1/settings            — настройки UI
PUT    /api/v1/settings            — обновить настройки

ANY    /api/v1/proxy/{service}/**  — произвольный прокси
       (блокирует /accounts, /transfers, /credits — используй прямые endpoint'ы)
```

**Настройки пользователя** хранятся в локальной PostgreSQL БД (не в Redis, несмотря на наличие Redis). Содержат:
- `theme`: `LIGHT` | `DARK`
- `hiddenAccounts`: список ID счетов, скрытых в интерфейсе

---

### 4.6 employee-bff (порт 8085)

По структуре идентичен `client-bff`. Разница в OAuth2-клиенте и scopes (`admin` вместо `accounts.*`, `credits.*`).

---

## 5. Межсервисное взаимодействие

### 5.1 Карта вызовов

```
auth-service    ──REST──►  user-service    (регистрация, загрузка ролей)
credit-service  ──REST──►  core-service    (зачисление кредита, списание платежа)
client-bff      ──REST──►  core-service    (счета, операции, переводы)
client-bff      ──REST──►  user-service    (резолюция userId по email)
client-bff      ──REST──►  credit-service  (кредиты, погашение)
employee-bff    ──REST──►  core-service    (те же + все счета)
employee-bff    ──REST──►  user-service    (управление пользователями)
employee-bff    ──REST──►  credit-service  (тарифы, кредиты)
core-service    ──Kafka──► core-service    (сам себе, через bank.operations)
core-service    ──Kafka──► client-bff      (уведомления через bank.operation-notifications)
core-service    ──Kafka──► employee-bff    (то же)
```

### 5.2 Технология вызовов

Все синхронные вызовы выполняются через **Spring RestClient** — блокирующий HTTP-клиент (Java 21 virtual threads потенциально помогают здесь). Никакого Feign.

Базовые URL настраиваются через `application.yml`:

```yaml
# credit-service
services:
  core-service:
    url: http://localhost:8080

# client-bff
services:
  core-service:
    url: http://localhost:8080
  user-service:
    url: http://localhost:8082
  credit-service:
    url: http://localhost:8083
```

### 5.3 Критические межсервисные вызовы

**1. auth-service → user-service (при аутентификации)**

Каждый раз, когда кто-то логинится, auth-service запрашивает user-service за ролями. Если user-service недоступен — аутентификация падает.

**2. credit-service → core-service (выдача кредита)**

```
Шаг 1: GET /api/v1/accounts/{accountId}     — проверить валюту счёта
Шаг 2: GET /api/v1/master-account?currency= — найти мастер-счёт нужной валюты
Шаг 3: POST /api/v1/master-account/transfer — перевести с мастер-счёта на счёт клиента
        { targetAccountId, amount, sourceCurrency }
```

Это синхронный вызов внутри транзакции создания кредита. Если core-service недоступен — кредит не создаётся, транзакция откатывается.

**3. client-bff → user-service (каждый запрос)**

На каждый API-вызов BFF резолвит `userId` через `GET /api/v1/users/by-email?email={email}`. Это дополнительный HTTP-запрос на каждый запрос клиента. Кеширования нет — потенциальная точка оптимизации.

---

## 6. Kafka и асинхронность

### 6.1 Зачем Kafka для операций

Операции по счетам (deposit, withdraw, transfer) **не выполняются синхронно** в HTTP-запросе. Вместо этого:

1. HTTP-запрос возвращает `202 Accepted` немедленно
2. Событие сохраняется в outbox-таблицу
3. Kafka-консьюмер обрабатывает событие асинхронно

Преимущества:
- Клиент не ждёт завершения обработки
- Повторные попытки при сбоях без потери события
- Идемпотентность через UUID-ключ

### 6.2 Топики

```
bank.operations                — команды: запросы на выполнение операций
  Partitions: 3
  Key:        accountId (строка)  ← обеспечивает ordering по счёту
  Value:      OperationEvent (JSON)

bank.operation-notifications   — события: уведомления об успешных операциях
  Partitions: 3
  Key:        accountId (строка)
  Value:      OperationResponse (JSON)
```

Ключ партиционирования по `accountId` гарантирует, что все операции по одному счёту обрабатываются одним консьюмером в порядке очереди.

### 6.3 OperationEvent

```json
{
  "idempotencyKey": "550e8400-e29b-41d4-a716-446655440000",
  "accountId": 1,
  "type": "DEPOSIT",
  "amount": 1000.00,
  "currency": "RUB",
  "relatedAccountId": null,
  "exchangeRate": null,
  "description": "Пополнение счёта"
}
```

### 6.4 Консьюмеры и retry-политики

**core-service (bank.operations):**
```
Group:    core-service
BackOff:  FixedBackOff(5000ms, 3 retries)
Logic:
  - InsufficientFundsException   → log.warn, не повторять (бизнес-ошибка)
  - AccountNotFoundException      → log.warn, не повторять
  - AccountClosedException        → log.warn, не повторять
  - ExchangeRateUnavailableException → rethrow → DefaultErrorHandler повторит
```

**client-bff (bank.operation-notifications):**
```
Group:    client-bff
BackOff:  FixedBackOff(2000ms, 3 retries)
Logic:
  - JsonProcessingException → log.error, skip (невалидный JSON — не повторять)
  - WebSocket ошибка       → пробрасывается → DefaultErrorHandler повторит
```

**employee-bff (bank.operation-notifications):**
```
Group:    employee-bff
BackOff:  FixedBackOff(2000ms, 3 retries)
Logic:    идентично client-bff
```

### 6.5 Сериализация

**Продюсер (core-service):**
- `JsonSerializer` со Spring `ObjectMapper` (с `JavaTimeModule`)
- Ключ: `StringSerializer`
- Отправляет `OperationEvent` или `OperationResponse` как JSON

**Консьюмер core-service:**
- `JsonDeserializer<OperationEvent>` — target type из аргумента `@KafkaListener`
- Trusted packages: `com.bank.core.dto.kafka`

**Консьюмер BFF:**
- `StringDeserializer` — получает сырую JSON-строку
- Парсинг вручную через `ObjectMapper.readTree()`

---

## 7. Transactional Outbox

### 7.1 Проблема без outbox

```
HTTP Request → OperationService.requestDeposit()
                    │
                    ├── kafkaTemplate.send()   ← Kafka может быть недоступна
                    │     └── Exception → событие потеряно навсегда
                    │
                    └── return 202 Accepted    ← клиент думает, что всё ок
```

### 7.2 Решение: outbox-паттерн

```
HTTP Request → OperationService.requestDeposit()
                    │
                    ├── OutboxEventService.save()  ← сохранить в БД (транзакционно)
                    │     └── INSERT INTO outbox_events (PENDING)
                    │
                    └── return 202 Accepted

                    ↕ каждые 500ms

OutboxEventPublisher.publishPendingEvents()
  SELECT * FROM outbox_events WHERE status='PENDING' ORDER BY created_at LIMIT 100
  FOR EACH event:
    kafkaTemplate.send(topic, key, payload).get(5 seconds)
    → success: UPDATE status='SENT', sent_at=now()
    → failure: retryCount++
               if retryCount >= 10: UPDATE status='FAILED'
```

### 7.3 Атомарность

Ключевой момент: событие **сохраняется в той же транзакции**, что и проверки перед операцией:

```
requestDeposit():
  1. findActiveAccount()    ← читает из БД
  2. создаём OperationEvent
  3. outboxEventService.save()  ← INSERT в outbox_events
  ─── если что-то выше упало → транзакция откатывается → событие не появится в outbox

processOperation() → @Transactional:
  1. проверка идемпотентности
  2. обновление баланса
  3. сохранение Operation
  4. notificationService.notifyNewOperation()
       └── outboxEventService.save()  ← тоже внутри той же транзакции
  ─── если операция в БД commit'нулась → уведомление гарантированно попадёт в outbox
```

### 7.4 Схема таблицы

```sql
CREATE TABLE outbox_events (
    id          BIGSERIAL    PRIMARY KEY,
    topic       VARCHAR(255) NOT NULL,        -- 'bank.operations' или 'bank.operation-notifications'
    event_key   VARCHAR(255),                 -- accountId (ключ партиции Kafka)
    payload     TEXT         NOT NULL,        -- JSON события
    status      VARCHAR(20)  NOT NULL DEFAULT 'PENDING',   -- PENDING|SENT|FAILED
    retry_count INT          NOT NULL DEFAULT 0,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    sent_at     TIMESTAMP                     -- NULL до успешной отправки
);
-- Частичный индекс только по PENDING — быстрый поиск для планировщика
CREATE INDEX idx_outbox_status_created ON outbox_events (status, created_at)
    WHERE status = 'PENDING';
```

### 7.5 Десериализация при публикации

Планировщик знает, какой класс использовать по имени топика:

```java
private Object deserialize(OutboxEvent event) {
    return switch (event.getTopic()) {
        case "bank.operations" ->
            objectMapper.readValue(event.getPayload(), OperationEvent.class);
        case "bank.operation-notifications" ->
            objectMapper.readValue(event.getPayload(), OperationResponse.class);
        default -> throw new IllegalArgumentException("Неизвестный топик");
    };
}
```

Затем объект передаётся в `kafkaTemplate.send()`, который сериализует его через `JsonSerializer` — сохраняя все заголовки типов.

---

## 8. WebSocket и real-time уведомления

### 8.1 Конфигурация STOMP

Все три сервиса (core-service, client-bff, employee-bff) имеют WebSocket:

```
Endpoint:         /ws/operations  (SockJS fallback)
Message broker:   /topic          (pub/sub, broadcast)
App prefix:       /app            (отправка серверу)
CORS:             allowedOriginPatterns = "*"
```

Подписка клиента: `/topic/accounts/{accountId}/operations`

### 8.2 Двойная рассылка уведомлений

После обработки операции в Kafka-консьюмере core-service:

```
OperationNotificationService.notifyNewOperation(operation):

  1. WebSocket (прямое подключение к core-service):
     messagingTemplate.convertAndSend(
         "/topic/accounts/{accountId}/operations", operation)

  2. Outbox → Kafka (для BFF-сервисов):
     outboxEventService.save("bank.operation-notifications", accountId, operation)
          ↓
     OutboxEventPublisher отправляет в Kafka
          ↓
     client-bff KafkaConsumer получает
          ↓
     messagingTemplate.convertAndSend(
         "/topic/accounts/{accountId}/operations", operation)
```

iOS-приложение подключается к `ws://localhost:8084/ws/operations` (client-bff). Получает уведомление через вторую ветку (через Kafka).

### 8.3 Формат уведомления (OperationResponse)

```json
{
  "id": 42,
  "accountId": 1,
  "type": "DEPOSIT",
  "amount": 1000.00,
  "currency": "RUB",
  "relatedAccountId": null,
  "exchangeRate": null,
  "description": "Пополнение счёта",
  "createdAt": "2024-01-15T12:30:00"
}
```

---

## 9. Базы данных

### 9.1 auth-service (bank_auth)

```sql
-- V1
auth_users(
    id           BIGSERIAL PRIMARY KEY,
    email        VARCHAR UNIQUE NOT NULL,
    password_hash VARCHAR NOT NULL,        -- bcrypt
    enabled      BOOLEAN DEFAULT TRUE
)

-- V2: INSERT default employee (admin@bank.com)

-- V3: OAuth2 хранилище авторизаций Spring Authorization Server
oauth2_authorization(...)             -- активные авторизации, токены
oauth2_authorization_consent(...)     -- согласия пользователей на scopes
```

### 9.2 core-service (bank_core)

```sql
-- V1
accounts(
    id           BIGSERIAL PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    currency     VARCHAR(3) CHECK (currency IN ('RUB', 'USD', 'EUR')),
    balance      NUMERIC(19,4) DEFAULT 0 CHECK (balance >= 0),
    account_type VARCHAR(10) CHECK (account_type IN ('PERSONAL', 'MASTER')),
    is_closed    BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP DEFAULT now(),
    updated_at   TIMESTAMP DEFAULT now(),
    version      BIGINT DEFAULT 0          -- оптимистичная блокировка
)
-- Уникальный индекс: uq_master_account_per_currency (account_type='MASTER', currency)
-- Гарантирует: один мастер-счёт на валюту

-- V2
operations(
    id               BIGSERIAL PRIMARY KEY,
    idempotency_key  UUID UNIQUE NOT NULL,  -- защита от дублирования
    account_id       BIGINT REFERENCES accounts(id),
    type             VARCHAR(20) CHECK (type IN ('DEPOSIT','WITHDRAWAL','TRANSFER_IN','TRANSFER_OUT')),
    amount           NUMERIC(19,4) CHECK (amount > 0),
    currency         VARCHAR(3),
    related_account_id BIGINT REFERENCES accounts(id),
    exchange_rate    NUMERIC(12,6),
    description      VARCHAR(500),
    created_at       TIMESTAMP DEFAULT now()
)
-- Индексы: account_id, created_at, (account_id, created_at DESC)

-- V3: INSERT мастер-счета RUB, USD, EUR

-- V4
outbox_events(...)  -- см. раздел 7
```

### 9.3 user-service (bank_user)

```sql
-- V1
users(
    id          BIGSERIAL PRIMARY KEY,
    email       VARCHAR UNIQUE NOT NULL,
    first_name  VARCHAR NOT NULL,
    last_name   VARCHAR NOT NULL,
    phone       VARCHAR,
    blocked     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT now(),
    updated_at  TIMESTAMP DEFAULT now()
)

user_roles(
    user_id BIGINT REFERENCES users(id),
    role    VARCHAR NOT NULL,   -- CLIENT, ADMIN, EMPLOYEE, MANAGER
    PRIMARY KEY (user_id, role)
)

-- V2: INSERT default employee (admin@bank.com, роль EMPLOYEE)
```

### 9.4 credit-service (bank_credit)

```sql
-- V1
tariffs(
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,   -- процент годовых
    min_amount   DECIMAL DEFAULT 1000,
    max_amount   DECIMAL DEFAULT 10000000,
    min_term_days INT DEFAULT 30,
    max_term_days INT DEFAULT 3650,
    active       BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT now()
)
-- V6: добавлена колонка currency (RUB/USD/EUR)

-- V2
credits(
    id           BIGSERIAL PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    account_id   BIGINT NOT NULL,
    tariff_id    BIGINT REFERENCES tariffs(id),
    principal    NUMERIC(19,4),       -- исходная сумма
    remaining    NUMERIC(19,4),       -- остаток долга
    interest_rate NUMERIC(5,2),       -- скопировано с тарифа в момент создания
    term_days    INT,
    daily_payment NUMERIC(19,4),      -- аннуитетный платёж
    status       VARCHAR(10) CHECK (status IN ('ACTIVE','CLOSED','OVERDUE')),
    created_at   TIMESTAMP DEFAULT now(),
    closed_at    TIMESTAMP,
    last_accrual_at TIMESTAMP DEFAULT now()   -- добавлено V4
)

-- V3
payments(
    id        BIGSERIAL PRIMARY KEY,
    credit_id BIGINT REFERENCES credits(id),
    amount    NUMERIC(19,4) NOT NULL,
    status    VARCHAR(10) CHECK (status IN ('PENDING','PAID','OVERDUE')),
    due_date  TIMESTAMP NOT NULL,
    paid_at   TIMESTAMP,
    created_at TIMESTAMP DEFAULT now()
)
-- Индексы: credit_id, status, due_date
```

### 9.5 client-bff / employee-bff

```sql
-- V1 (обе БД идентичны)
user_settings(
    user_id         BIGINT PRIMARY KEY,
    theme           VARCHAR(10) DEFAULT 'LIGHT',  -- LIGHT, DARK
    hidden_accounts TEXT DEFAULT ''               -- comma-separated account IDs
)
```

---

## 10. Бизнес-процессы

### 10.1 Регистрация и первый вход

```
1. Client → POST /api/v1/auth/register
   { email, password, firstName, lastName, phone }

2. auth-service:
   a. Проверить email в auth_users → 409 если занят
   b. bcrypt(password) → сохранить AuthUser
   c. POST /api/v1/users → user-service
      { email, firstName, lastName, phone, roles: ["CLIENT"] }
   d. user-service создаёт User + user_roles

3. Первый OAuth2 Login:
   a. Client открывает: GET http://localhost:8081/oauth2/authorize
      ?client_id=client-bff&response_type=code&scope=openid profile accounts.read...
      &redirect_uri=bankapp://callback&code_challenge=xxx&code_challenge_method=S256
   b. auth-service → redirect на /login (HTML-форма)
   c. Пользователь вводит email + password
   d. CustomUserDetailsService: GET /api/v1/users/by-email → user-service
      → проверить blocked=false → получить роли
   e. BCrypt verify password
   f. auth-service → redirect на bankapp://callback?code=xxx
   g. Client: POST /oauth2/token
      { code, code_verifier, grant_type=authorization_code }
   h. auth-service → { access_token (JWT, 1h), refresh_token (30d), id_token }
```

### 10.2 Пополнение счёта

```
iOS App → POST /api/v1/accounts/{id}/deposit
          Authorization: Bearer {jwt}
          { "amount": 5000.00 }
    │
    ▼
client-bff:
  1. Verify JWT (проверить подпись, exp, issuer)
  2. Резолвить userId: jwt.subject → GET /api/v1/users/by-email → userId
  3. checkAccountOwnership: GET /api/v1/accounts/{id} → account.userId == userId?
  4. POST /api/v1/accounts/{id}/deposit → core-service { "amount": 5000.00 }
  5. → 202 Accepted (передаётся клиенту)
    │
    ▼
core-service:
  6. findActiveAccount(accountId)       — бросает если закрыт/не найден
  7. Создать OperationEvent { UUID, accountId, DEPOSIT, 5000, RUB, ... }
  8. OutboxEventService.save() → INSERT outbox_events (PENDING)
  9. → 202 Accepted
    │
    ▼ (асинхронно, через ~500ms)

OutboxEventPublisher:
  10. SELECT PENDING events LIMIT 100
  11. Deserialize → OperationEvent
  12. kafkaTemplate.send("bank.operations", accountId, event).get(5s)
  13. UPDATE outbox_events status='SENT'
    │
    ▼
KafkaOperationConsumer (core-service):
  14. Receive OperationEvent
  15. OperationService.processOperation():
      a. existsByIdempotencyKey → skip если дубликат
      b. @Transactional:
         - lockAccount(accountId) ← SELECT FOR UPDATE
         - account.balance += 5000
         - save(account)
         - save(Operation { idempotencyKey, DEPOSIT, ... })
         - notificationService.notifyNewOperation(operation)
              ├── messagingTemplate.convertAndSend() ← WebSocket прямой
              └── outboxEventService.save() ← уведомление в outbox
    │
    ▼ (асинхронно)

OutboxEventPublisher:
  16. SELECT PENDING notification events
  17. kafkaTemplate.send("bank.operation-notifications", accountId, operationResponse)
    │
    ▼
OperationNotificationConsumer (client-bff):
  18. Receive OperationResponse
  19. messagingTemplate.convertAndSend("/topic/accounts/{id}/operations", data)
    │
    ▼
iOS App (WebSocket):
  20. Получает push-уведомление об операции
  21. UI обновляет баланс и историю операций
```

### 10.3 Перевод между счетами в разных валютах

```
iOS → POST /api/v1/transfers
      { fromAccountId: 1 (USD), toAccountId: 2 (RUB), amount: 100 }

client-bff:
  1. checkAccountOwnership(fromAccountId=1)
  2. POST /api/v1/transfers → core-service

core-service OperationService.requestTransfer():
  3. findActiveAccount(1)   → { USD, balance: 1000 }
  4. findActiveAccount(2)   → { RUB, balance: 500 }
  5. validateSufficientFunds: 1000 >= 100 ✓
  6. Currencies differ → ExchangeRateService.getRate(USD, RUB)
     a. @Cacheable("exchangeRates") → кеш на 60 минут
     b. GET https://open.er-api.com/v6/latest/USD
     c. rate = 1/0.011 ≈ 90.909 RUB за 1 USD
  7. Создать OperationEvent {
       type: TRANSFER_OUT, accountId: 1,
       relatedAccountId: 2, amount: 100,
       currency: USD, exchangeRate: 90.909
     }
  8. outboxEventService.save()

KafkaOperationConsumer → processTransfer():
  9. Блокировать счета (id 1 < id 2 → lock 1 first, then 2)
  10. Validate sufficient funds: 1000 >= 100 ✓
  11. convertedAmount = 100 * 90.909 = 9090.9 RUB
  12. account1.balance = 1000 - 100 = 900 USD
  13. account2.balance = 500 + 9090.9 = 9590.9 RUB
  14. Сохранить Operation TRANSFER_OUT для account1
  15. Сохранить Operation TRANSFER_IN для account2 (idempotencyKey = hash(original_key + "_IN"))
  16. Уведомить оба счёта через Kafka/WebSocket
```

### 10.4 Выдача кредита

```
iOS → POST /api/v1/credits
      { tariffId: 1, amount: 100000, termDays: 365 }
      (userId и accountId инжектируются из JWT/ownership check в BFF)

client-bff:
  1. Резолвить userId
  2. checkAccountOwnership(accountId)
  3. POST /api/v1/credits → credit-service

credit-service CreditService.createCredit():
  4. findTariff(tariffId) → { interestRate: 15%, minAmount: 10000, currency: RUB }
  5. GET /api/v1/accounts/{accountId} → core-service → { currency: RUB } ✓
  6. Validate amount: 10000 <= 100000 <= 10000000 ✓
  7. Validate term: 30 <= 365 <= 3650 ✓
  8. dailyRate    = 0.15 / (365 * 24 * 60) ≈ 2.85e-7
  9. dailyPayment = 100000 * dailyRate / (1 - (1+dailyRate)^-365)
  10. Сохранить Credit { principal:100000, remaining:100000, status:ACTIVE }
  11. Создать 365 Payment записей (schedule)
  12. GET /api/v1/master-account?currency=RUB → core-service → masterAccountId
  13. POST /api/v1/master-account/transfer → core-service
      { targetAccountId: clientAccountId, amount: 100000, sourceCurrency: RUB }
      → Kafka event → консьюмер списывает с мастер-счёта, зачисляет на клиентский
  14. → 201 CreditResponse
```

---

## 11. Надёжность системы

### 11.1 Слои надёжности

```
┌──────────────────────────────────────────────────────────┐
│  Уровень 1: Idempotency (защита от дубликатов)           │
│  ─ Каждая операция имеет UUID idempotencyKey             │
│  ─ При повторном получении → skip (not reprocess)        │
│  ─ Transfer IN имеет детерминированный ключ:             │
│    UUID.nameUUIDFromBytes(originalKey + "_IN")           │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│  Уровень 2: Transactional Outbox                         │
│  ─ Event сохраняется в БД ДО отправки в Kafka            │
│  ─ Если Kafka недоступна → событие остаётся в outbox     │
│  ─ Планировщик повторяет каждые 500ms                    │
│  ─ До 10 попыток, затем FAILED (требует ручного разбора) │
│  ─ Outbox save в той же транзакции с бизнес-данными      │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│  Уровень 3: Kafka Consumer Retry                         │
│  ─ core-service: FixedBackOff(5s, 3 retries)            │
│  ─ client/employee-bff: FixedBackOff(2s, 3 retries)     │
│  ─ Transient errors (ExchangeRate) → retry               │
│  ─ Business errors (InsufficientFunds) → no retry        │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│  Уровень 4: Database Transactions                        │
│  ─ @Transactional на processOperation()                  │
│  ─ Pessimistic locking (SELECT FOR UPDATE) на трансферах │
│  ─ Deadlock prevention: всегда lock в порядке id         │
│  ─ Optimistic locking (@Version) на Account              │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│  Уровень 5: Business Validation                          │
│  ─ Проверка баланса ДО отправки в Kafka (в HTTP-запросе) │
│  ─ Проверка снова ПОСЛЕ блокировки счёта в консьюмере   │
│  ─ Двойная проверка = защита от race conditions          │
└──────────────────────────────────────────────────────────┘
```

### 11.2 Гарантии

| Ситуация | Что происходит |
|----------|---------------|
| Kafka временно недоступна | Событие ждёт в outbox_events (PENDING), отправится когда Kafka вернётся |
| Дублирующееся Kafka-сообщение | `existsByIdempotencyKey()` → операция пропускается |
| Два одновременных списания | SELECT FOR UPDATE блокирует второй запрос; второй получит актуальный баланс |
| ExchangeRate сервис недоступен | Kafka retry (3 попытки × 5s); если не успел — событие остаётся в очереди (pending offset) |
| core-service упал в середине processOperation | Транзакция откатится; Kafka offset не коммитится; сообщение будет обработано повторно |

### 11.3 Слабые места

| Проблема | Описание |
|----------|----------|
| **No saga / compensation** | Если после создания AuthUser вызов user-service упал — auth_users содержит запись без соответствующего User |
| **Sync auth dep** | Каждый login требует вызова user-service; если он недоступен — вход невозможен |
| **userId resolution per request** | client-bff вызывает user-service на каждый запрос для резолюции userId |
| **FAILED outbox events** | После 10 попыток событие помечается FAILED — требует ручного вмешательства или механизма алертинга |
| **Single Kafka partition per account** | Операции по счёту обрабатываются строго последовательно — throughput ограничен |
| **No circuit breaker** | Нет Resilience4j или аналога; при недоступности сервиса запросы просто падают |

---

## 12. Ошибки и их обработка

### 12.1 Единый формат ошибок

Каждый сервис имеет `@RestControllerAdvice` с единым форматом ответа:

```json
{
  "message": "Недостаточно средств на счёте 1: требуется 500.00 RUB, доступно 200.00 RUB",
  "status": 400,
  "timestamp": "2024-01-15T12:30:00"
}
```

### 12.2 Каталог исключений

**core-service:**

| Exception | HTTP | Когда |
|-----------|------|-------|
| `AccountNotFoundException` | 404 | Счёт не найден |
| `AccountClosedException` | 400 | Счёт закрыт |
| `InsufficientFundsException` | 400 | Не хватает средств |
| `AccountNotEmptyException` | 400 | Попытка закрыть счёт с ненулевым балансом |
| `ExchangeRateUnavailableException` | 503 | Внешний сервис курсов недоступен |

**credit-service:**

| Exception | HTTP | Когда |
|-----------|------|-------|
| `CreditNotFoundException` | 404 | Кредит не найден |
| `CreditAlreadyClosedException` | 400 | Попытка операции с закрытым кредитом |
| `InvalidCreditAmountException` | 400 | Сумма вне диапазона тарифа / несовпадение валюты |
| `TariffNotFoundException` | 404 | Тариф не найден |

**auth-service / user-service:**

| Exception | HTTP | Когда |
|-----------|------|-------|
| `EmailAlreadyExistsException` | 409 | Email занят |
| `UserNotFoundException` | 404 | Пользователь не найден |

**client-bff / employee-bff:**

| Exception | HTTP | Когда |
|-----------|------|-------|
| `ResourceAccessDeniedException` | 403 | Попытка доступа к чужому ресурсу |

### 12.3 Поведение Kafka-консьюмера при ошибках

```
processOperation() бросает исключение
         │
         ├── InsufficientFundsException
         │     → catch в KafkaOperationConsumer
         │     → log.warn (бизнес-ошибка, повтор бесполезен)
         │     → offset закоммичен, событие не повторяется
         │
         ├── AccountNotFoundException / AccountClosedException
         │     → то же самое
         │
         └── ExchangeRateUnavailableException
               → rethrow из KafkaOperationConsumer
               → DefaultErrorHandler перехватывает
               → FixedBackOff(5s): попытки 1, 2, 3
               → После 3 попыток: offset закоммичен,
                 событие попадает в Dead Letter Topic (если настроен)
                 или просто пропускается с логом
```

---

## Приложение: Быстрый старт

```bash
# 1. Поднять инфраструктуру
docker-compose up -d

# 2. Собрать все сервисы
cd backend && ./gradlew build

# 3. Запустить сервисы (в отдельных терминалах)
./gradlew :auth-service:bootRun
./gradlew :user-service:bootRun
./gradlew :core-service:bootRun
./gradlew :credit-service:bootRun
./gradlew :client-bff:bootRun
./gradlew :employee-bff:bootRun

# 4. Проверить здоровье
curl http://localhost:8081/.well-known/openid-configuration
curl http://localhost:8080/api/v1/master-account

# 5. Swagger UI
http://localhost:8080/swagger-ui.html  # core-service
http://localhost:8082/swagger-ui.html  # user-service
http://localhost:8083/swagger-ui.html  # credit-service
http://localhost:8084/swagger-ui.html  # client-bff
```
