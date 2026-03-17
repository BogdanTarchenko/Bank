package com.bank.employeebff.service;

import com.bank.employeebff.dto.SettingsResponse;
import com.bank.employeebff.dto.UpdateSettingsRequest;
import com.bank.employeebff.model.Theme;
import com.bank.employeebff.model.UserSettings;
import com.bank.employeebff.repository.UserSettingsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SettingsService {

    private final UserSettingsRepository settingsRepository;

    @Transactional(readOnly = true)
    public SettingsResponse getSettings(Long userId) {
        UserSettings settings = settingsRepository.findByUserId(userId)
                .orElseGet(() -> createDefaultSettings(userId));
        return toResponse(settings);
    }

    @Transactional
    public SettingsResponse updateSettings(Long userId, UpdateSettingsRequest request) {
        UserSettings settings = settingsRepository.findByUserId(userId)
                .orElseGet(() -> createDefaultSettings(userId));

        if (request.theme() != null) {
            settings.setTheme(request.theme());
        }
        if (request.hiddenAccounts() != null) {
            settings.setHiddenAccounts(
                    request.hiddenAccounts().stream()
                            .map(String::valueOf)
                            .collect(Collectors.joining(","))
            );
        }

        return toResponse(settingsRepository.save(settings));
    }

    private UserSettings createDefaultSettings(Long userId) {
        UserSettings settings = UserSettings.builder()
                .userId(userId)
                .theme(Theme.LIGHT)
                .hiddenAccounts("")
                .build();
        return settingsRepository.save(settings);
    }

    private SettingsResponse toResponse(UserSettings settings) {
        List<Long> hiddenAccounts = settings.getHiddenAccounts() == null || settings.getHiddenAccounts().isBlank()
                ? Collections.emptyList()
                : Arrays.stream(settings.getHiddenAccounts().split(","))
                        .map(Long::parseLong)
                        .toList();

        return new SettingsResponse(settings.getUserId(), settings.getTheme(), hiddenAccounts);
    }
}
