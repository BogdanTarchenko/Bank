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

Система построена как **Java-монорепо** с шестью микросервисами, объединёнными в единый Gradle multi-module build. Каждый сервис — отдельный Spring Boot процесс со своей базой данных.

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
│  BFF для iOS клиента      │   │  BFF для сотрудников       │
│  • hasRole(CLIENT)        │   │  • hasRole(EMPLOYEE)       │
│  • Ownership checks       │   │  • Role management         │
│  • User settings          │   │  • User settings           │
│  • Token invalidation     │   │  • Token invalidation      │
│  • WebSocket relay        │   │  • WebSocket relay         │
└──────┬─────────┬──────────┘   └───────┬─────────┬──────────┘
       │         │                      │         │
       │   Kafka Consumer               │   Kafka Consumer
       │ bank.operation-notifications   │ bank.operation-notifications
       │         │ (groupId: client-bff)│         │ (groupId: employee-bff)
       │         └──────────┬───────────┘         │
       │                    │ WebSocket            │
       │  REST (RestClient) │                      │ REST (RestClient)
       │                    ▼                      │
┌──────▼────────────────────────────┬──────────────▼──────────────────┐
│         core-service :8080        │         credit-service :8083     │
│  • Счета (PERSONAL + MASTER)      │  • Кредиты, тарифы              │
│  • Операции (async via Kafka)     │  • График платежей              │
│  • Переводы (inter-account)       │  • Кредитный рейтинг            │
│  • Transactional Outbox           │  • Scheduler (ежедневные платежи)│
│  • WebSocket (STOMP)              │  • HTTP → core-service           │
│  • Kafka producer + consumer      │                                  │
└──────┬────────────────────────────┘                                  │
       │                                                               │
  outbox_events → KafkaProducer                                        │
  bank.operations + bank.operation-notifications                       │
       │                                                               │
┌──────▼────────────────────────────┐                                  │
│  KafkaOperationConsumer           │ ←────────────────────────────────┘
│  (core-service, groupId: core)    │   credit-service вызывает:
│  • processOperation(event)        │   • /api/v1/master-account/transfer
│  • обновляет балансы              │   • /api/v1/accounts/{id}/withdraw
│  • шлёт WebSocket + Kafka notif.  │
└───────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     user-service :8082                              │
│  • Профили пользователей, роли (CLIENT / EMPLOYEE / ADMIN)          │
│  • Блокировка пользователей                                         │
│  • Вызывается: auth-service (register), BFF (resolve userId, roles) │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     auth-service :8081                              │
│  • OAuth2 Authorization Server (Spring Authorization Server)        │
│  • Форм-вход (HTML /login)                                          │
│  • Выдаёт JWT-токены (AUTHORIZATION_CODE + REFRESH_TOKEN)           │
│  • При регистрации → синхронный HTTP вызов → user-service           │
└─────────────────────────────────────────────────────────────────────┘
```

### Принципы дизайна

| Принцип | Реализация |
|---------|-----------|
| **Service-per-database** | Каждый сервис — своя PostgreSQL БД; прямой доступ к чужой БД запрещён |
| **BFF pattern** | client-bff и employee-bff — серверная часть конкретных клиентов, хранят UI-настройки |
| **Event-driven** | Операции по счетам идут через Kafka: at-least-once доставка |
| **Transactional Outbox** | Продюсеры сохраняют события в БД до отправки в Kafka |
| **OAuth2 SSO** | Единая точка входа через auth-service, пароль вводится только там |
| **Idempotency** | Каждая операция имеет UUID-ключ, повторное выполнение безопасно |

---

## 2. Инфраструктура

### Порты сервисов

| Сервис | Порт | БД | БД порт |
|--------|------|----|---------|
| auth-service | 8081 | bank_auth | 5433 |
| core-service | 8080 | bank_core | 5432 |
| user-service | 8082 | bank_user | 5434 |
| credit-service | 8083 | bank_credit | 5435 |
| client-bff | 8084 | bank_client_bff | 5436 |
| employee-bff | 8085 | bank_employee_bff | 5437 |

### Docker Compose сервисы

- **PostgreSQL x6** — по одной БД на сервис (изоляция данных)
- **Redis** — хранение инвалидированных токенов и кеш сессий в BFF
- **Apache Kafka + Zookeeper** — брокер событий для операций

### Tech Stack

| Компонент | Технология |
|-----------|-----------|
| Язык | Java 21 |
| Фреймворк | Spring Boot 3.4 |
| Сборка | Gradle Kotlin DSL (multi-module) |
| БД | PostgreSQL 17 |
| Миграции | Flyway (versioned SQL) |
| ORM | Spring Data JPA + Hibernate |
| Брокер | Apache Kafka |
| Кеш/сессии | Redis |
| Аутентификация | Spring Authorization Server (OAuth2) |
| Real-time | WebSocket STOMP |
| HTTP клиент | RestClient (Spring 6) |
| Boilerplate | Lombok |

---

## 3. OAuth2 и безопасность

### Общая схема

```
iOS App                  auth-service :8081              client-bff :8084
   │                           │                               │
   │  1. GET /oauth2/authorization/auth-service                │
   │──────────────────────────────────────────────────────────►│
   │                           │ 2. redirect → /login          │
   │◄──────────────────────────────────────────────────────────│
   │                           │                               │
   │  3. POST /login (email + password)                        │
   │──────────────────────────►│                               │
   │                           │ 4. redirect с code            │
   │◄──────────────────────────│                               │
   │                           │                               │
   │  5. POST /oauth2/token (code + PKCE verifier)             │
   │──────────────────────────────────────────────────────────►│
   │                           │◄──────────────────────────────│
   │                           │  6. выдаёт access_token + refresh_token
   │◄──────────────────────────────────────────────────────────│
   │                           │                               │
   │  7. API запрос (Bearer: access_token)                     │
   │──────────────────────────────────────────────────────────►│
   │                           │  8. проверяет JWT (подпись, claims)
   │◄──────────────────────────────────────────────────────────│
```

### Зарегистрированные OAuth2-клиенты

| Клиент | Redirect URI | Scopes |
|--------|-------------|--------|
| `client-bff` | `http://localhost:8084/login/oauth2/code/auth-service`, `bankapp://callback` | openid, profile, accounts.read, accounts.write, credits.read, credits.write |
| `employee-bff` | `http://localhost:8085/login/oauth2/code/auth-service`, `bankemployee://callback` | openid, profile, accounts.read, accounts.write, credits.read, credits.write, admin |

- **Grant types**: `AUTHORIZATION_CODE` + `REFRESH_TOKEN`
- **PKCE**: обязателен (для мобильных клиентов без client_secret)
- **Access token TTL**: 1 час
- **Refresh token TTL**: 30 дней

### JWT Claims

Стандартные OIDC-поля + кастомные, добавляемые `TokenCustomizer`:

```json
{
  "sub": "user@example.com",
  "iat": 1711000000,
  "exp": 1711003600,
  "roles": ["ROLE_CLIENT"],
  "scope": "openid profile accounts.read accounts.write"
}
```

Роли из `roles` claim конвертируются в Spring Security `GrantedAuthority` через `RolesClaimConverter` в BFF.

### Безопасность внутренних сервисов

**core-service, user-service, credit-service** — `permitAll()` на все эндпоинты. Безопасность обеспечивается на уровне BFF:
- только client-bff и employee-bff обращаются к внутренним сервисам;
- внутренние сервисы не экспонированы наружу.

**client-bff** — `hasRole("CLIENT")` для всех запросов, кроме WebSocket.

**employee-bff** — `hasRole("EMPLOYEE")` для всех запросов, кроме WebSocket.

### Инвалидация токенов (Token Invalidation)

При изменении ролей пользователя employee-bff записывает в Redis:

```
KEY:   roles:invalidated:{user@email.com}
VALUE: System.currentTimeMillis()  (метка инвалидации)
TTL:   30 дней (время жизни refresh token)
```

`TokenInvalidationFilter` в обоих BFF при каждом запросе:
1. Читает `iat` (issued at) из JWT
2. Достаёт метку инвалидации из Redis по ключу `roles:invalidated:{email}`
3. Если `iat < invalidatedAt` → возвращает `401 UNAUTHORIZED`
4. Клиент вынужден пройти re-login и получить новый токен с актуальными ролями

### Регистрация пользователя

```
Client ──POST /api/v1/auth/register──► auth-service
                                            │
                          создаёт AuthUser в auth_users
                                            │
                          POST /api/v1/users ──► user-service
                                            │
                          создаёт User с ролью CLIENT в users
```

Пароль хранится только в auth-service (BCrypt hash). user-service паролей не знает.

---

## 4. Сервисы — подробно

### 4.1 auth-service (:8081)

**Назначение**: OAuth2 Authorization Server. Единственная точка входа паролей.

**Эндпоинты:**
```
POST /api/v1/auth/register    — регистрация нового пользователя
GET  /login                   — HTML форма входа (для OAuth2 flow)
POST /oauth2/token            — обмен authorization code на JWT
GET  /oauth2/authorization/*  — начало OAuth2 flow (redirect)
```

**Модели данных:**
```
auth_users: id, email, password_hash, enabled, created_at
OAuth2 системные таблицы (JdbcOAuth2AuthorizationService):
  oauth2_authorization, oauth2_authorization_consent, oauth2_registered_client
```

**Межсервисное взаимодействие:**
- → `user-service`: `POST /api/v1/users` при регистрации (синхронный RestClient)

---

### 4.2 core-service (:8080)

**Назначение**: управление счетами, выполнение финансовых операций, переводы, курсы валют.

**Эндпоинты:**
```
# Счета
POST   /api/v1/accounts                   — создать счёт
GET    /api/v1/accounts                   — все счета (или ?userId=X)
GET    /api/v1/accounts/{id}              — счёт по ID
DELETE /api/v1/accounts/{id}              — закрыть счёт (баланс должен быть 0)

# Операции (асинхронные — возвращают 202 ACCEPTED)
POST   /api/v1/accounts/{id}/deposit      — пополнение
POST   /api/v1/accounts/{id}/withdraw     — снятие
GET    /api/v1/accounts/{id}/operations   — история операций (пагинация)

# Переводы (асинхронные — 202 ACCEPTED)
POST   /api/v1/transfers                  — перевод между счетами

# Мастер-счета (используются credit-service)
GET    /api/v1/master-account             — список всех мастер-счетов
GET    /api/v1/master-account?currency=X  — мастер-счёт по валюте
POST   /api/v1/master-account/transfer    — перевод с мастер-счёта на счёт клиента

# WebSocket STOMP
WS     /ws/operations                     — точка подключения
SUB    /topic/accounts/{id}/operations    — подписка на события счёта
```

**Ключевые модели данных:**

```sql
accounts:
  id, user_id, currency (RUB/USD/EUR), balance (NUMERIC 19,4 >= 0),
  account_type (PERSONAL/MASTER), is_closed, created_at, updated_at,
  version (для optimistic locking)
  UNIQUE(account_type, currency) WHERE account_type='MASTER'

operations:
  id, idempotency_key (UUID UNIQUE), account_id, type (DEPOSIT/WITHDRAWAL/TRANSFER_IN/TRANSFER_OUT),
  amount, currency, related_account_id, exchange_rate, description, created_at

outbox_events:
  id, topic, event_key, payload (JSON text), status (PENDING/SENT/FAILED),
  retry_count, created_at, sent_at
  INDEX ON (status, created_at) WHERE status='PENDING'
```

**Логика операций:**

`OperationService` разделён на два этапа:

1. **Request** (синхронный HTTP handler → возвращает 202):
   - Проверяет существование и активность счёта
   - Для withdraw/transfer — проверяет достаточность баланса
   - Для cross-currency — получает курс от ExchangeRateService
   - Создаёт `OperationEvent` и кладёт в outbox через `KafkaOperationProducer`

2. **Process** (асинхронный Kafka consumer):
   - Проверяет идемпотентность по `idempotency_key`
   - DEPOSIT: `balance += amount`
   - WITHDRAWAL: `balance -= amount`
   - TRANSFER: блокирует оба счёта `SELECT FOR UPDATE` в порядке возрастания ID (deadlock prevention), конвертирует сумму при разных валютах, создаёт пару операций (TRANSFER_OUT + TRANSFER_IN)
   - Отправляет WebSocket-уведомление + Kafka-нотификацию (через outbox)

---

### 4.3 user-service (:8082)

**Назначение**: хранение профилей пользователей и управление ролями.

**Эндпоинты:**
```
POST   /api/v1/users                — создать пользователя
GET    /api/v1/users                — все пользователи
GET    /api/v1/users/{id}           — пользователь по ID
GET    /api/v1/users/by-email       — поиск по email (используется BFF для resolve userId)
PUT    /api/v1/users/{id}           — обновить данные
PATCH  /api/v1/users/{id}/roles     — заменить набор ролей
PATCH  /api/v1/users/{id}/block     — заблокировать
PATCH  /api/v1/users/{id}/unblock   — разблокировать
GET    /api/v1/users/roles          — список доступных ролей
```

**Модели данных:**
```sql
users: id, email, first_name, last_name, phone, blocked (DEFAULT FALSE), created_at, updated_at
user_roles: user_id (FK), role (CLIENT/EMPLOYEE/ADMIN) — PK (user_id, role)
```

---

### 4.4 credit-service (:8083)

**Назначение**: выдача кредитов, управление тарифами, расписание платежей, кредитный рейтинг.

**Эндпоинты:**
```
POST   /api/v1/credits                — создать кредит
GET    /api/v1/credits/{id}           — кредит по ID (включает начисленные проценты)
GET    /api/v1/credits?userId=X       — кредиты пользователя
GET    /api/v1/credits/{id}/payments  — расписание платежей
POST   /api/v1/credits/{id}/repay     — погашение кредита

GET    /api/v1/tariffs                — активные тарифы
POST   /api/v1/tariffs                — создать тариф

GET    /api/v1/credit-rating?userId=X — кредитный рейтинг пользователя
```

**Модели данных:**
```sql
tariffs:
  id, name, currency, interest_rate (DECIMAL 5,2 — годовая %),
  min_amount, max_amount (DECIMAL 19,2), min_term_days, max_term_days, active, created_at

credits:
  id, user_id, account_id, tariff_id, principal (DECIMAL 19,2),
  remaining (DECIMAL 19,2), interest_rate (DECIMAL 5,2), term_days,
  daily_payment (DECIMAL 19,2), status (ACTIVE/OVERDUE/CLOSED),
  created_at, closed_at, last_accrual_at

payments:
  id, credit_id, amount, status (PENDING/PAID/OVERDUE), due_date, paid_at
```

**Логика создания кредита:**
1. Проверяет тариф активен
2. Проверяет валюта счёта = валюта тарифа
3. Сумма в диапазоне `[min_amount, max_amount]`, срок в `[min_term_days, max_term_days]`
4. Вычисляет аннуитетный платёж: `daily_payment = P * r / (1 - (1+r)^(-n))`, где `r = annual_rate / 100 / 365`
5. Генерирует расписание платежей (1 платёж в день, последний = остаток + проценты)
6. `POST /api/v1/master-account/transfer` → перечисляет сумму кредита на счёт клиента
7. Устанавливает `last_accrual_at = now()`

**Начисление процентов (при просмотре/погашении):**
```
minutes_elapsed = now() - last_accrual_at (в минутах)
accrued_interest = remaining * ((1 + minute_rate)^minutes_elapsed - 1)
```

**PaymentScheduler (ежедневно в 00:00):**
```
Для каждого PENDING платежа с due_date <= now():
  ├── CoreServiceClient.withdrawFromAccount(credit.accountId, payment.amount)
  ├── При успехе: payment.status = PAID, credit.remaining -= principal_part
  │   └── Если remaining <= 0: credit.status = CLOSED
  └── При ошибке (InsufficientFunds): payment.status = OVERDUE, credit.status = OVERDUE
```

**Кредитный рейтинг:**
```
score = 850 - (overdue_payments_count * 50) + (closed_credits_count * 10)
Диапазон: [300, 850]
Грейды: EXCELLENT (≥750), GOOD (650-749), FAIR (550-649), POOR (450-549), BAD (<450)
```

---

### 4.5 client-bff (:8084)

**Назначение**: BFF для iOS-клиента. Авторизует запросы, проверяет владение ресурсами, хранит UI-настройки, релеит WebSocket-уведомления.

**Эндпоинты (проксирование + логика):**
```
GET    /api/v1/accounts                   — мои счета (userId из JWT)
GET    /api/v1/accounts/{id}              — мой счёт (+ проверка владения)
POST   /api/v1/accounts                   — создать счёт (userId из JWT)
DELETE /api/v1/accounts/{id}              — закрыть свой счёт
POST   /api/v1/accounts/{id}/deposit      — пополнить свой счёт
POST   /api/v1/accounts/{id}/withdraw     — снять со своего счёта
GET    /api/v1/accounts/{id}/operations   — история операций

GET    /api/v1/credits                    — мои кредиты
GET    /api/v1/credits/{id}               — мой кредит (+ проверка владения)
POST   /api/v1/credits                    — создать кредит
GET    /api/v1/credits/{id}/payments      — платежи по кредиту
POST   /api/v1/credits/{id}/repay         — погасить кредит
GET    /api/v1/credit-rating              — мой кредитный рейтинг

POST   /api/v1/transfers                  — перевод между счетами

GET    /api/v1/settings                   — мои UI-настройки
PUT    /api/v1/settings                   — обновить настройки

GET    /api/v1/proxy/{service}/**         — прозрачное проксирование
```

**UserResolverService**: при каждом запросе извлекает `email` из JWT (`sub` claim), делает `GET /api/v1/users/by-email?email=...` в user-service и получает `userId`. Этот userId используется для всех последующих операций.

**ResourceOwnershipService**: перед выполнением операции над счётом/кредитом проверяет, что ресурс принадлежит текущему пользователю.

**SettingsService**: хранит в локальной БД `user_settings` (тема LIGHT/DARK, массив скрытых счетов `hidden_account_ids`).

**UI-настройки (user_settings):**
```sql
user_settings: id, user_id, theme (LIGHT/DARK), hidden_account_ids (TEXT JSON), created_at, updated_at
```

---

### 4.6 employee-bff (:8085)

**Назначение**: BFF для приложения сотрудника. Отличия от client-bff:
- Требует роль `EMPLOYEE` вместо `CLIENT`
- Имеет `RoleManagementController` для управления ролями пользователей

**Дополнительный функционал:**
```
PATCH /api/v1/users/{id}/roles   — изменить роли пользователя
```

**RoleManagementService** после успешного обновления ролей в user-service:
```
Redis.set("roles:invalidated:{email}", System.currentTimeMillis())
```
Это инвалидирует все текущие токены пользователя через `TokenInvalidationFilter`.

---

## 5. Межсервисное взаимодействие

### Кто кого вызывает

```
auth-service  ──POST /api/v1/users──────────────────────► user-service

client-bff    ──GET /api/v1/users/by-email──────────────► user-service
client-bff    ──GET/POST/DELETE /api/v1/accounts/**─────► core-service
client-bff    ──POST /api/v1/transfers──────────────────► core-service
client-bff    ──GET/POST /api/v1/credits/**─────────────► credit-service
client-bff    ──GET /api/v1/tariffs────────────────────► credit-service
client-bff    ──GET /api/v1/credit-rating──────────────► credit-service

employee-bff  ──(аналогично client-bff)──────────────────► все сервисы
employee-bff  ──PATCH /api/v1/users/{id}/roles───────────► user-service

credit-service ──GET /api/v1/accounts/{id}───────────────► core-service
credit-service ──POST /api/v1/master-account/transfer────► core-service
credit-service ──POST /api/v1/accounts/{id}/withdraw─────► core-service
```

### Паттерн HTTP клиентов

Все межсервисные вызовы используют Spring `RestClient` с захардкоженными base URL из application.yml:

```yaml
services:
  core-service.url: http://localhost:8080
  user-service.url: http://localhost:8082
  credit-service.url: http://localhost:8083
```

Синхронные вызовы: ошибки бросают исключения, которые обрабатываются через `@RestControllerAdvice`.

---

## 6. Kafka и асинхронность

### Топики

| Топик | Продюсер | Консьюмеры | Назначение |
|-------|----------|-----------|-----------|
| `bank.operations` | core-service | core-service (`core-service`) | Команды на выполнение операций |
| `bank.operation-notifications` | core-service | client-bff (`client-bff`), employee-bff (`employee-bff`) | Уведомления о завершённых операциях |

### Жизненный цикл операции

```
HTTP POST /deposit
    │
    ▼
OperationService.requestDeposit()
    │  проверки + создаёт OperationEvent
    ▼
KafkaOperationProducer.sendOperation()
    │  НЕ отправляет в Kafka напрямую!
    ▼
outbox_events INSERT (status=PENDING, topic='bank.operations')
    │
    │  (через ~500мс)
    ▼
OutboxEventPublisher (@Scheduled fixedDelay=500ms)
    │  читает до 100 PENDING событий
    ▼
KafkaTemplate.send(topic, key, payload)
    │  при успехе: status=SENT
    │  при ошибке: retry_count++, при >=10 → status=FAILED
    ▼
KafkaOperationConsumer (groupId: core-service)
    │  десериализует OperationEvent
    ▼
OperationService.processOperation()
    │  выполняет изменение баланса в БД
    │  проверяет idempotency_key (UNIQUE constraint)
    ▼
OperationNotificationService.notifyNewOperation()
    │
    ├──► WebSocket: /topic/accounts/{id}/operations (прямая отправка через STOMP)
    │
    └──► outbox_events INSERT (status=PENDING, topic='bank.operation-notifications')
              │  (через ~500мс)
              ▼
         OutboxEventPublisher → KafkaTemplate.send('bank.operation-notifications', ...)
              │
              ▼
         OperationNotificationConsumer (client-bff, groupId: client-bff)
         OperationNotificationConsumer (employee-bff, groupId: employee-bff)
              │
              ▼
         WebSocket relay: /topic/accounts/{id}/operations
```

### Обработка ошибок в консьюмерах

**core-service (bank.operations):**

| Исключение | Поведение |
|-----------|----------|
| `InsufficientFundsException` | Log WARN, сообщение пропускается (бизнес-ошибка, retry не поможет) |
| `AccountNotFoundException` | Log WARN, пропускается |
| `AccountClosedException` | Log WARN, пропускается |
| `ExchangeRateUnavailableException` | Бросается наружу → `DefaultErrorHandler`: 3 retry с задержкой 5 с |

**client-bff, employee-bff (bank.operation-notifications):**

| Ситуация | Поведение |
|---------|----------|
| Ошибка парсинга JSON | Log ERROR, пропускается (повторка не поможет) |
| Ошибка отправки WebSocket | Бросается наружу → `DefaultErrorHandler`: 3 retry с задержкой 2 с |

---

## 7. Transactional Outbox

**Проблема**: если сервис упадёт после успешного commit в БД, но до отправки в Kafka — событие потеряется.

**Решение**: Transactional Outbox Pattern.

### Схема таблицы outbox_events

```sql
CREATE TABLE outbox_events (
    id         BIGSERIAL PRIMARY KEY,
    topic      VARCHAR(255) NOT NULL,        -- 'bank.operations' или 'bank.operation-notifications'
    event_key  VARCHAR(255),                 -- Kafka ключ (accountId) для партиционирования
    payload    TEXT NOT NULL,                -- JSON сериализованное событие
    status     VARCHAR(20) NOT NULL          -- 'PENDING', 'SENT', 'FAILED'
               DEFAULT 'PENDING',
    retry_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    sent_at    TIMESTAMP
);

CREATE INDEX ON outbox_events (status, created_at) WHERE status = 'PENDING';
```

### OutboxEventPublisher (Scheduler)

```java
@Scheduled(fixedDelay = 500)  // каждые 500мс
void publishPendingEvents() {
    List<OutboxEvent> events = outboxRepo.findTop100ByStatusOrderByCreatedAt(PENDING);
    for (OutboxEvent event : events) {
        try {
            kafkaTemplate.send(event.getTopic(), event.getEventKey(), event.getPayload())
                         .get(5, TimeUnit.SECONDS);  // sync wait
            event.setStatus(SENT);
            event.setSentAt(now());
        } catch (Exception e) {
            event.setRetryCount(event.getRetryCount() + 1);
            if (event.getRetryCount() >= 10) {
                event.setStatus(FAILED);
            }
        }
        outboxRepo.save(event);
    }
}
```

### Гарантии

- **Атомарность**: запись в outbox_events — часть той же транзакции, что и бизнес-данные. Либо оба commit, либо ни одного.
- **At-least-once**: scheduler читает PENDING события до тех пор, пока они не станут SENT.
- **Идемпотентность на стороне консьюмера**: `idempotency_key` (UUID UNIQUE) защищает от дублирования операций при повторной доставке.
- **Dead-letter**: события с `retry_count >= 10` переходят в статус FAILED и требуют ручного разбора.
- **Производительность**: индекс `WHERE status='PENDING'` на `(status, created_at)` позволяет эффективно выбирать только необработанные события.

---

## 8. WebSocket и real-time уведомления

### Конфигурация STOMP (core-service и оба BFF)

```java
configureMessageBroker:
  enableSimpleBroker("/topic")          // in-memory брокер
  setApplicationDestinationPrefixes("/app")

registerStompEndpoints:
  "/ws/operations"                      // точка подключения
  allowedOriginPatterns("*")            // CORS
```

### Топология уведомлений

```
core-service                    client-bff
     │                               │
     │ OperationNotificationService  │
     │                               │
     ├──► STOMP /topic/accounts/{id}/operations  ──► клиент (прямое соединение с core)
     │     (прямая отправка через SimpMessagingTemplate)
     │
     └──► outbox_events (bank.operation-notifications)
               │
               ▼
          Kafka → OperationNotificationConsumer (client-bff)
               │
               ▼
          STOMP /topic/accounts/{id}/operations  ──► клиент (через BFF)
```

Уведомление приходит **двумя путями** — напрямую от core-service (если клиент подключён туда) и через BFF (основной path для iOS).

iOS-клиент подключается по WebSocket к `client-bff:8084/ws/operations` и подписывается на `/topic/accounts/{accountId}/operations`.

---

## 9. Базы данных

### auth-service

```
V1 — auth_users (id, email, password_hash, enabled, created_at)
V2 — INSERT default employee user
V3 — OAuth2 системные таблицы (oauth2_authorization, oauth2_authorization_consent, oauth2_registered_client)
```

### core-service

```
V1 — accounts (id, user_id, currency, balance, account_type, is_closed, version, created_at, updated_at)
V2 — operations (id, idempotency_key, account_id, type, amount, currency, related_account_id, exchange_rate, description, created_at)
V3 — INSERT master accounts (RUB, USD, EUR с начальным balance=1,000,000,000)
V4 — outbox_events (id, topic, event_key, payload, status, retry_count, created_at, sent_at)
```

### user-service

```
V1 — users (id, email, first_name, last_name, phone, blocked, created_at, updated_at)
   — user_roles (user_id, role) — PK (user_id, role), ON DELETE CASCADE
V2 — INSERT default employee user
```

### credit-service

```
V1 — tariffs (id, name, interest_rate, min/max amount, min/max term_days, active, created_at)
V2 — credits (id, user_id, account_id, tariff_id, principal, remaining, interest_rate, term_days, daily_payment, status, created_at, closed_at)
V3 — payments (id, credit_id, amount, status, due_date, paid_at)
V4 — ADD COLUMN last_accrual_at в credits (для расчёта начисленных процентов)
V5 — Изменить тип interest_rate на DECIMAL(5,2)
V6 — ADD COLUMN currency в tariffs
```

### client-bff / employee-bff

```
V1 — user_settings (id, user_id, theme, hidden_account_ids, created_at, updated_at)
```

---

## 10. Бизнес-процессы

### Регистрация и первый вход

```
1. Клиент отправляет POST /api/v1/auth/register {email, password, firstName, lastName, phone}
2. auth-service создаёт AuthUser (пароль BCrypt хеш)
3. auth-service вызывает POST /api/v1/users в user-service → создаётся User с ролью CLIENT
4. Клиент инициирует OAuth2 flow (GET /oauth2/authorization/auth-service)
5. Редирект на /login форму в auth-service
6. Ввод email/password → auth-service генерирует authorization code
7. Редирект на BFF с code
8. BFF обменивает code на JWT (POST /oauth2/token)
9. iOS сохраняет access_token + refresh_token
```

### Пополнение счёта

```
1. POST /api/v1/accounts/{id}/deposit (Bearer JWT)
2. client-bff проверяет JWT (hasRole CLIENT, не инвалидирован)
3. client-bff проверяет владение счётом (ResourceOwnershipService)
4. client-bff → POST /api/v1/accounts/{id}/deposit → core-service
5. core-service: проверяет счёт, создаёт OperationEvent, пишет в outbox_events
6. HTTP ответ: 202 ACCEPTED (операция принята, но ещё не выполнена)
7. [через ~500мс] OutboxEventPublisher отправляет событие в Kafka
8. KafkaOperationConsumer обрабатывает: balance += amount
9. OperationNotificationService отправляет WebSocket уведомление + пишет нотификацию в outbox
10. [через ~500мс] OutboxEventPublisher публикует нотификацию в bank.operation-notifications
11. OperationNotificationConsumer (client-bff) получает → WebSocket relay
12. iOS получает уведомление по WebSocket
```

### Перевод между счетами в разных валютах

```
1. POST /api/v1/transfers {fromAccountId, toAccountId, amount, currency}
2. BFF проверки → core-service
3. core-service: проверяет оба счёта, получает курс (ExchangeRateService)
4. Создаёт OperationEvent (type=TRANSFER_OUT) с exchange_rate
5. → outbox → Kafka → consumer
6. consumer: SELECT FOR UPDATE обоих счетов (в порядке возрастания ID)
7. Конвертирует: convertedAmount = amount * exchange_rate
8. from: balance -= amount
9. to:   balance += convertedAmount
10. Создаёт 2 записи в operations (TRANSFER_OUT + TRANSFER_IN)
11. Отправляет уведомления по обоим счетам
```

### Выдача кредита

```
1. POST /api/v1/credits {accountId, tariffId, amount, termDays}
2. BFF → credit-service
3. Проверка: тариф активен, валюта совпадает, сумма и срок в диапазоне
4. Расчёт аннуитетного платежа
5. Создание расписания (N платежей)
6. CoreServiceClient.transferFromMasterAccount(accountId, amount, currency)
   → POST /api/v1/master-account/transfer → core-service
   (синхронный вызов: мастер-счёт → счёт клиента, через Kafka)
7. credit.status = ACTIVE, last_accrual_at = now()
8. 202 ACCEPTED (деньги поступят после обработки Kafka)
```

### Погашение кредита

```
1. POST /api/v1/credits/{id}/repay {amount}
2. credit-service: рассчитывает начисленные проценты с last_accrual_at до now()
3. repayAmount = min(request.amount, remaining + accruedInterest)
4. CoreServiceClient.withdrawFromAccount(accountId, repayAmount)
   → POST /api/v1/accounts/{id}/withdraw → core-service (через Kafka)
5. Распределение: сначала гасит проценты, остаток → principal
6. Отмечает PAID платежи по расписанию
7. Если remaining <= 0: credit.status = CLOSED
```

---

## 11. Надёжность системы

### Уровни гарантий

| Уровень | Механизм | Гарантия |
|---------|---------|---------|
| **Запись операции** | Transactional Outbox | Операция сохраняется атомарно с бизнес-данными |
| **Доставка в Kafka** | OutboxEventPublisher + retry_count | До 10 попыток с интервалом 500мс |
| **Обработка операции** | idempotency_key (UNIQUE) | Дублированное сообщение не создаёт дублированную операцию |
| **Обновление баланса** | Optimistic locking (version field) | Параллельные изменения одного счёта не создают race condition |
| **Deadlock prevention** | SELECT FOR UPDATE в порядке возрастания ID | Переводы между двумя счетами не дедлочатся |
| **Повторки консьюмеров** | DefaultErrorHandler(FixedBackOff) | Временные ошибки (курс обмена, WebSocket) retry-ятся |
| **Инвалидация токенов** | Redis + TokenInvalidationFilter | Токены инвалидируются мгновенно при смене ролей |
| **Mастер-счета** | 3 счёта (RUB/USD/EUR) с балансом 1 млрд | Кредиты обеспечены достаточным резервом |

### Потенциальные точки отказа и их обработка

| Ситуация | Последствие | Защита |
|---------|-------------|--------|
| Kafka недоступна | Операции не выполняются | outbox_events хранит PENDING до восстановления |
| Kafka недоступна долго | retry_count достигает 10 | Событие → FAILED, требует ручного разбора |
| core-service упал после INSERT outbox | Событие не потеряно | OutboxEventPublisher обработает при рестарте |
| Дублирование сообщения Kafka | Повторное выполнение операции | idempotency_key защищает от дублей |
| ExchangeRate API недоступен | Трансфер не выполняется | 3 retry (5с), затем пропуск сообщения |
| Недостаточно средств на счёте | Withdraw не проходит | Сообщение пропускается без retry |
| Пользователь потерял токен | Неавторизованный доступ | Токен живёт 1 час; refresh token 30 дней |
| Смена ролей | Старые токены дают некорректные права | Redis инвалидация + TokenInvalidationFilter |

### Производительность outbox

- Scheduler запускается каждые **500мс** (2 раза в секунду)
- Обрабатывает до **100 событий** за один запуск
- Пропускная способность: ~200 операций/сек при нормальной работе Kafka
- Индекс `WHERE status='PENDING'` обеспечивает эффективный scan только нужных строк

---

## 12. Ошибки и их обработка

### HTTP ошибки

Все сервисы используют `@RestControllerAdvice` с единым форматом ответа:

```json
{
  "status": 404,
  "error": "NOT_FOUND",
  "message": "Account not found: 123",
  "timestamp": "2026-03-22T12:00:00Z"
}
```

### Коды ответов

| HTTP код | Когда |
|---------|------|
| `202 ACCEPTED` | Операция принята в outbox (deposit/withdraw/transfer) |
| `400 BAD REQUEST` | Невалидные данные (JSR-303 validation) |
| `401 UNAUTHORIZED` | Токен отсутствует, невалиден, или инвалидирован |
| `403 FORBIDDEN` | Токен валиден, но недостаточно прав (роль) |
| `404 NOT FOUND` | Ресурс не существует |
| `409 CONFLICT` | Бизнес-нарушение (счёт закрыт, недостаточно средств) |
| `422 UNPROCESSABLE ENTITY` | Логическая ошибка (несовместимые валюты, невалидный диапазон) |

### Бизнес-исключения в core-service

| Исключение | Код | Описание |
|-----------|-----|---------|
| `AccountNotFoundException` | 404 | Счёт не найден |
| `AccountClosedException` | 409 | Счёт закрыт |
| `InsufficientFundsException` | 409 | Недостаточно средств |
| `ExchangeRateUnavailableException` | 503 | Курс обмена недоступен |
| `ResourceAccessDeniedException` | 403 | Счёт не принадлежит пользователю |
