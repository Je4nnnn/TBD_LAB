package com.drones.controller;

import com.drones.dto.DroneDtos.CrearDronReq; // Importar
import com.drones.service.DroneService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/drones")
public class DroneController {
    private final DroneService drones;
    public DroneController(DroneService drones) { this.drones = drones; }

    @GetMapping
    public ResponseEntity<?> listar(){
        return ResponseEntity.ok(drones.listar());
    }

    // --- NUEVO ENDPOINT ---
    @PostMapping
    public ResponseEntity<?> crear(@RequestBody @Valid CrearDronReq req){
        var id = drones.crear(req);
        return ResponseEntity.ok(Map.of("id", id));
    }
    // ----------------------
}