package com.drones.controller;

import com.drones.service.DroneService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/drones")
public class DroneController {
    private final DroneService drones;
    public DroneController(DroneService drones) { this.drones = drones; }

    @GetMapping
    public ResponseEntity<?> listar(){
        return ResponseEntity.ok(drones.listar());
    }
}
