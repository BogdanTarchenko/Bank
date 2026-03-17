package com.bank.employeebff.dto;

import com.bank.employeebff.model.Theme;

import java.util.List;

public record SettingsResponse(
        Long userId,
        Theme theme,
        List<Long> hiddenAccounts
) {}
