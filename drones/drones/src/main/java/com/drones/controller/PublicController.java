package com.drones.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/public")
public class PublicController {
    @GetMapping("/ping")
    public ResponseEntity<?> ping(){ return ResponseEntity.ok(java.util.Map.of("status","ok")); }
}
