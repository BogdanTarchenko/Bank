package com.bank.clientbff.config;

import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.RetryRegistry;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ResilienceConfig {
    // Beans are auto-configured by resilience4j-spring-boot3
    // This class is kept for any future customization
}
