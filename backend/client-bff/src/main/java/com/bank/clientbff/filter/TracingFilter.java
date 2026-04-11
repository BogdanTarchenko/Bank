package com.bank.clientbff.filter;

import com.bank.clientbff.service.MonitoringClient;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
@Order(1)
@RequiredArgsConstructor
@Slf4j
public class TracingFilter extends OncePerRequestFilter {

    private final MonitoringClient monitoringClient;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String traceId = request.getHeader("X-Trace-Id");
        if (traceId == null || traceId.isBlank()) {
            traceId = UUID.randomUUID().toString();
        }
        response.setHeader("X-Trace-Id", traceId);
        long start = System.currentTimeMillis();
        String method = request.getMethod();
        String path = request.getRequestURI();
        try {
            chain.doFilter(request, response);
        } finally {
            long duration = System.currentTimeMillis() - start;
            int status = response.getStatus();
            log.info("[TRACE:{}] {} {} -> {} ({}ms)", traceId, method, path, status, duration);
            monitoringClient.send(traceId, method, path, status, duration, status >= 500 ? "HTTP " + status : null);
        }
    }
}
