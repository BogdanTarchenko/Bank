package com.bank.monitoring.controller;

import com.bank.monitoring.service.MetricService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
@RequiredArgsConstructor
public class DashboardController {

    private final MetricService metricService;

    @GetMapping("/")
    public String index(Model model, @RequestParam(defaultValue = "1") int hours) {
        model.addAttribute("services", metricService.getAllServices());
        model.addAttribute("hours", hours);
        return "dashboard";
    }

    @GetMapping("/dashboard")
    public String dashboard(Model model, @RequestParam(defaultValue = "1") int hours) {
        model.addAttribute("services", metricService.getAllServices());
        model.addAttribute("hours", hours);
        return "dashboard";
    }
}
