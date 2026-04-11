package com.bank.clientbff.filter;

import com.bank.clientbff.model.IdempotencyRecord;
import com.bank.clientbff.repository.IdempotencyRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.Set;

@Component
@Order(3)
@RequiredArgsConstructor
@Slf4j
public class IdempotencyFilter extends OncePerRequestFilter {

    private final IdempotencyRepository idempotencyRepository;

    private static final Set<String> IDEMPOTENT_METHODS = Set.of("POST", "PUT", "PATCH");

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String idempotencyKey = request.getHeader("Idempotency-Key");
        String method = request.getMethod();

        if (idempotencyKey == null || !IDEMPOTENT_METHODS.contains(method)) {
            chain.doFilter(request, response);
            return;
        }

        Optional<IdempotencyRecord> existing = idempotencyRepository.findByIdempotencyKey(idempotencyKey);
        if (existing.isPresent()) {
            IdempotencyRecord record = existing.get();
            log.info("[IDEMPOTENCY] Повторный запрос с ключом {}, возврат кешированного ответа", idempotencyKey);
            response.setStatus(record.getResponseStatus());
            response.setContentType("application/json;charset=UTF-8");
            response.setHeader("X-Idempotency-Replayed", "true");
            if (record.getResponseBody() != null) {
                response.getWriter().write(record.getResponseBody());
            }
            return;
        }

        ContentCachingResponseWrapper wrappedResponse = new ContentCachingResponseWrapper(response);
        chain.doFilter(request, wrappedResponse);

        String responseBody = new String(wrappedResponse.getContentAsByteArray(), StandardCharsets.UTF_8);
        idempotencyRepository.save(IdempotencyRecord.builder()
                .idempotencyKey(idempotencyKey)
                .method(method)
                .path(request.getRequestURI())
                .responseStatus(wrappedResponse.getStatus())
                .responseBody(responseBody)
                .build());
        wrappedResponse.copyBodyToResponse();
    }
}
