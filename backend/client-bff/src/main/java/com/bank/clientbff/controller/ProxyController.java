package com.bank.clientbff.controller;

import com.bank.clientbff.service.ProxyService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/proxy")
@RequiredArgsConstructor
public class ProxyController {

    private final ProxyService proxyService;

    @RequestMapping(value = "/{service}/**", method = {
            RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT,
            RequestMethod.PATCH, RequestMethod.DELETE
    })
    public ResponseEntity<String> proxy(
            @PathVariable String service,
            @RequestBody(required = false) String body,
            HttpMethod method,
            HttpServletRequest request) {

        String fullPath = request.getRequestURI();
        String proxyPrefix = "/api/v1/proxy/" + service;
        String targetPath = fullPath.substring(proxyPrefix.length());

        return proxyService.proxy(service, targetPath, method, body, request);
    }
}
