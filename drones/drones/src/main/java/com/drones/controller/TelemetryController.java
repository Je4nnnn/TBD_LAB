package com.drones.controller;

import com.drones.dto.MissionDtos.TelemetriaReq;
import com.drones.service.MissionService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/telemetria")
public class TelemetryController {
    private final MissionService missions;
    public TelemetryController(MissionService missions){ this.missions = missions; }

    @PostMapping
    public ResponseEntity<?> registrar(@RequestBody @Valid TelemetriaReq req){
        missions.registrarTelemetria(req);
        return ResponseEntity.ok().build();
    }
}
