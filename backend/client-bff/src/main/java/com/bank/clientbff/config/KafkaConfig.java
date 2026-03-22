package com.bank.clientbff.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.FixedBackOff;

@Configuration
public class KafkaConfig {

    /**
     * Retry-политика для консюмеров: 3 попытки с паузой 2 секунды.
     * Spring Boot автоматически применяет этот бин к ConcurrentKafkaListenerContainerFactory.
     */
    @Bean
    public DefaultErrorHandler errorHandler() {
        return new DefaultErrorHandler(new FixedBackOff(2000L, 3));
    }
}
