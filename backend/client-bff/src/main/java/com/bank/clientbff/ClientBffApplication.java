package com.bank.clientbff;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class ClientBffApplication {

    public static void main(String[] args) {
        SpringApplication.run(ClientBffApplication.class, args);
    }
}
