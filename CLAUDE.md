# Bank — Monorepo

Банковское приложение: Java backend (microservices) + iOS client (Swift).

## Tech Stack

### Backend
- **Java 21**, **Spring Boot 3.4**, **Gradle Kotlin DSL**
- **PostgreSQL 17** — каждый сервис имеет свою БД (service-per-database)
- **Apache Kafka** — брокер сообщений для операций по счетам
- **Redis** — кеширование и хранение сессий в BFF-сервисах
- **Spring Security + OAuth 2.0 Authorization Server** — SSO аутентификация
- **WebSocket (STOMP)** — real-time обновления операций

### iOS
- **Swift 6**, **SwiftUI**, **Xcode 16**
- Layered architecture: UI → UseCases → Network

## Project Structure

```
Bank/
├── backend/                    # Java monorepo (Gradle multi-module)
│   ├── core-service/           # Port 8080 — счета, балансы, история операций
│   ├── auth-service/           # Port 8081 — SSO, OAuth2 Authorization Server
│   ├── user-service/           # Port 8082 — данные пользователей
│   ├── credit-service/         # Port 8083 — кредиты, тарифы, рейтинг
│   ├── client-bff/             # Port 8084 — BFF для клиентского приложения
│   └── employee-bff/           # Port 8085 — BFF для приложения сотрудника
├── ios/BankApp/                # iOS Swift проект
├── docker-compose.yml          # PostgreSQL, Redis, Kafka
└── docs/                       # Требования и диаграммы
```

## Architecture Principles

- **Service-per-database**: каждый сервис владеет своей БД. Прямой доступ к чужой БД запрещён — только через API.
- **BFF pattern**: client-bff и employee-bff являются серверной частью клиентских приложений. Хранят настройки UI (тема, скрытые счета). Проксируют запросы к внутренним сервисам.
- **Event-driven**: операции по счетам проходят через Kafka. Гарантия: ни одна операция не должна быть потеряна.
- **OAuth 2.0 SSO**: единая точка входа через auth-service. Пароль вводится ТОЛЬКО на странице auth-service. Никакой другой сервис не имеет доступа к паролям.

## Build & Run

```bash
# Set Java
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home

# Start infrastructure
docker-compose up -d

# Build backend
cd backend && ./gradlew build

# Run specific service
cd backend && ./gradlew :core-service:bootRun
```

## Conventions

### Java
- Package structure: `com.bank.<service>.<layer>` (controller, service, repository, model, dto, config)
- Use Lombok (@Data, @Builder, @RequiredArgsConstructor) for boilerplate reduction
- DTOs for API communication between services; never expose JPA entities directly
- Use `record` for immutable DTOs where possible
- Validation via `@Valid` + Jakarta Validation annotations
- Handle errors via `@RestControllerAdvice` with unified error response format

### REST API
- Prefix: `/api/v1/`
- Use proper HTTP methods and status codes
- Inter-service communication: RestClient (synchronous) with service-specific Feign-like interfaces

### Database
- Migrations managed via Flyway (versioned SQL scripts in `src/main/resources/db/migration/`)
- Naming: `V{number}__{description}.sql`
- JPA ddl-auto: `validate` (schema managed by Flyway, not Hibernate)

### Testing
- Unit tests: JUnit 5 + Mockito
- Integration tests: @SpringBootTest + Testcontainers
- Test naming: `methodName_condition_expectedResult`

### Git Commits
- Описания коммитов: краткие, на русском языке
- НЕ добавлять Co-Authored-By
- Авторство по сервисам:
  - **auth-service** → `BogdanTarchenko <tarchenko.bogdan@outlook.com>`
  - **core-service, client-bff, employee-bff** → `VLsoft-eng <deeeaddrop@gmail.com>`
  - **user-service, credit-service** → `VyacheslavTarasov2005 <v.t.45@mail.ru>`
- Общие файлы (CLAUDE.md, docker-compose, root gradle) → `BogdanTarchenko <tarchenko.bogdan@outlook.com>`
