dependencies {
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-oauth2-authorization-server")
    implementation("org.springframework.boot:spring-boot-starter-thymeleaf")
    runtimeOnly("org.postgresql:postgresql")
    testImplementation("org.springframework.security:spring-security-test")
}
