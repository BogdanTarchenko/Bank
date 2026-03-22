package com.bank.core.service;

import com.bank.core.model.OutboxEvent;
import com.bank.core.model.OutboxEventStatus;
import com.bank.core.repository.OutboxEventRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class OutboxEventService {

    private final OutboxEventRepository outboxEventRepository;
    private final ObjectMapper objectMapper;

    public void save(String topic, String key, Object payload) {
        try {
            String json = objectMapper.writeValueAsString(payload);
            OutboxEvent event = OutboxEvent.builder()
                    .topic(topic)
                    .eventKey(key)
                    .payload(json)
                    .status(OutboxEventStatus.PENDING)
                    .retryCount(0)
                    .build();
            outboxEventRepository.save(event);
        } catch (JsonProcessingException e) {
            log.error("Не удалось сериализовать событие для outbox: topic={}, key={}", topic, key, e);
            throw new RuntimeException("Ошибка сериализации события для outbox", e);
        }
    }
}
