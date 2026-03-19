package com.bank.core.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.boot.autoconfigure.kafka.KafkaProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.kafka.support.serializer.JsonSerializer;
import org.springframework.util.backoff.FixedBackOff;

@Configuration
public class KafkaConfig {

    public static final String OPERATIONS_TOPIC = "bank.operations";
    public static final String OPERATION_NOTIFICATIONS_TOPIC = "bank.operation-notifications";

    @Bean
    public NewTopic operationsTopic() {
        return TopicBuilder.name(OPERATIONS_TOPIC)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic operationNotificationsTopic() {
        return TopicBuilder.name(OPERATION_NOTIFICATIONS_TOPIC)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public DefaultErrorHandler errorHandler() {
        return new DefaultErrorHandler(new FixedBackOff(5000L, 3));
    }

    /**
     * ProducerFactory со Spring ObjectMapper (включает JavaTimeModule для корректной сериализации дат).
     */
    @Bean
    public ProducerFactory<String, Object> producerFactory(
            KafkaProperties kafkaProperties, ObjectMapper objectMapper) {
        var props = kafkaProperties.buildProducerProperties(null);
        return new DefaultKafkaProducerFactory<>(props,
                new StringSerializer(),
                new JsonSerializer<>(objectMapper));
    }

    @Bean
    public KafkaTemplate<String, Object> kafkaTemplate(ProducerFactory<String, Object> producerFactory) {
        return new KafkaTemplate<>(producerFactory);
    }
}
