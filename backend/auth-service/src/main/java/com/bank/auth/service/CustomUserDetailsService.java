package com.bank.auth.service;

import com.bank.auth.repository.AuthUserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class CustomUserDetailsService implements UserDetailsService {

    private final AuthUserRepository authUserRepository;
    private final RestClient.Builder restClientBuilder;

    @Value("${services.user-service.url}")
    private String userServiceUrl;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        var authUser = authUserRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("Пользователь не найден: " + email));

        List<GrantedAuthority> authorities = new ArrayList<>();
        authorities.add(new SimpleGrantedAuthority("ROLE_USER"));

        try {
            var userResponse = restClientBuilder.build()
                    .get()
                    .uri(userServiceUrl + "/api/v1/users/by-email?email=" + email)
                    .retrieve()
                    .body(new ParameterizedTypeReference<Map<String, Object>>() {});

            if (userResponse != null && userResponse.containsKey("roles")) {
                @SuppressWarnings("unchecked")
                var roles = (List<String>) userResponse.get("roles");
                for (String role : roles) {
                    authorities.add(new SimpleGrantedAuthority("ROLE_" + role));
                }
            }
        } catch (Exception e) {
            log.warn("Не удалось получить роли из user-service для {}: {}", email, e.getMessage());
        }

        return new User(
                authUser.getEmail(),
                authUser.getPasswordHash(),
                authUser.isEnabled(),
                true, true, true,
                authorities
        );
    }
}
