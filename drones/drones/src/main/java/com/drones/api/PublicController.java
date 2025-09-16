package com.drones.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/public")
public class PublicController {
    @GetMapping("/ping")
    public Map<String,String> ping() {
        return Map.of("status","ok","time", Instant.now().toString());
    }
}
