package com.bank.core.config;

import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.cache.annotation.CacheEvict;

@Configuration
@EnableCaching
@EnableScheduling
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        return new ConcurrentMapCacheManager("exchangeRates");
    }

    @Scheduled(fixedRate = 3600000)
    @CacheEvict(value = "exchangeRates", allEntries = true)
    public void evictExchangeRateCache() {
        // Очистка кеша курсов валют каждые 60 минут
    }
}
