package com.bank.user.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.concurrent.ThreadLocalRandom;

@Component
@Order(1)
@Slf4j
public class ChaosFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        // Skip actuator/swagger/health endpoints
        String path = request.getRequestURI();
        if (path.startsWith("/actuator") || path.startsWith("/swagger") || path.startsWith("/v3/api-docs")) {
            chain.doFilter(request, response);
            return;
        }

        int minute = LocalDateTime.now().getMinute();
        boolean isEvenMinute = minute % 2 == 0;
        double threshold = isEvenMinute ? 0.70 : 0.30;

        if (ThreadLocalRandom.current().nextDouble() < threshold) {
            log.warn("[CHAOS] Симуляция сбоя: {} {}", request.getMethod(), path);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                "{\"status\":500,\"error\":\"Internal Server Error\",\"message\":\"Simulated service failure (chaos)\",\"timestamp\":\""
                + LocalDateTime.now() + "\"}"
            );
            return;
        }

        chain.doFilter(request, response);
    }
}
