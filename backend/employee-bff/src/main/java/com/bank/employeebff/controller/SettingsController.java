package com.bank.employeebff.controller;

import com.bank.employeebff.dto.SettingsResponse;
import com.bank.employeebff.dto.UpdateSettingsRequest;
import com.bank.employeebff.service.SettingsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/settings")
@RequiredArgsConstructor
public class SettingsController {

    private final SettingsService settingsService;

    @GetMapping
    public SettingsResponse getSettings(@RequestParam Long userId) {
        return settingsService.getSettings(userId);
    }

    @PutMapping
    public SettingsResponse updateSettings(@RequestParam Long userId,
                                            @RequestBody UpdateSettingsRequest request) {
        return settingsService.updateSettings(userId, request);
    }
}
