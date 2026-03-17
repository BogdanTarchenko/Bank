package com.bank.clientbff.dto;

import com.bank.clientbff.model.Theme;

import java.util.List;

public record SettingsResponse(
        Long userId,
        Theme theme,
        List<Long> hiddenAccounts
) {}
