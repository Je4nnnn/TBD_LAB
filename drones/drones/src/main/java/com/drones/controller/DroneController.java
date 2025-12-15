package com.drones.controller;

import com.drones.dto.DroneDtos.CrearDronReq; // Importar
import com.drones.service.DroneService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

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

    // Eliminar dron
    @DeleteMapping("/{id}")
    public ResponseEntity<?> eliminar(@PathVariable UUID id) {
        var auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        System.out.println("[DroneController] DELETE /drones/" + id + " - Autenticación: " + (auth != null && auth.isAuthenticated() ? "SÍ (Usuario: " + auth.getName() + ")" : "NO"));
        if (auth == null || !auth.isAuthenticated()) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED).build();
        }
        try {
            drones.eliminar(id);
            return ResponseEntity.noContent().build();
        } catch (org.springframework.web.server.ResponseStatusException e) {
            throw e; // Re-lanzar para que Spring lo maneje correctamente
        }
    }
}