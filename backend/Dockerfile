FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app
COPY gradle/ gradle/
COPY gradlew build.gradle.kts settings.gradle.kts ./

ARG SERVICE_NAME
COPY ${SERVICE_NAME}/ ${SERVICE_NAME}/

# Alpine uses POSIX `sh`, so `gradlew` from Windows may contain CRLF (`\r\n`).
# Also, the repo may miss `gradle-wrapper.jar`, so we bootstrap it when needed.
RUN chmod +x gradlew \
    && sed -i 's/\r$//' gradlew \
    && apk add --no-cache curl ca-certificates unzip \
    && GRADLE_VERSION="$(sed -n 's/.*gradle-\([0-9.]*\)-bin\.zip.*/\1/p' gradle/wrapper/gradle-wrapper.properties)" \
    && curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip \
    && unzip -q /tmp/gradle.zip -d /tmp \
    && /tmp/gradle-${GRADLE_VERSION}/bin/gradle :${SERVICE_NAME}:bootJar -x test --no-daemon \
    && rm -rf /tmp/gradle-${GRADLE_VERSION} /tmp/gradle.zip

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
ARG SERVICE_NAME
COPY --from=builder /app/${SERVICE_NAME}/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
