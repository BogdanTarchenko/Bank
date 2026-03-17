package com.bank.credit.repository;

import com.bank.credit.model.Tariff;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TariffRepository extends JpaRepository<Tariff, Long> {

    List<Tariff> findByActiveTrue();
}
