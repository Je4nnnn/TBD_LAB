package com.drones.controller;

import com.drones.dto.MissionDtos;
import com.drones.dto.MissionDtos.CompletarReq;
import com.drones.dto.MissionDtos.FallarReq;
import com.drones.dto.MissionDtos.CrearReq; // Importamos el nuevo DTO
import com.drones.service.MissionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/misiones")
public class MissionController {
    private final MissionService missions;
    public MissionController(MissionService missions){ this.missions = missions; }

    @GetMapping
    public ResponseEntity<?> listar(){ return ResponseEntity.ok(missions.listar()); }

    // --- NUEVO ENDPOINT ---
    @PostMapping
    public ResponseEntity<?> crear(@RequestBody CrearReq req){
        UUID id = missions.crear(req);
        return ResponseEntity.ok(Map.of("id", id));
    }
    // ----------------------

    // NUEVO: actualizar misión
    @PutMapping("/{misionId}")
    public ResponseEntity<?> actualizar(
            @PathVariable UUID misionId,
            @RequestBody MissionDtos.ActualizarReq req
    ) {
        missions.actualizar(misionId, req);
        return ResponseEntity.noContent().build();
    }

    // NUEVO: eliminar misión (DELETE duro)
    @DeleteMapping("/{misionId}")
    public ResponseEntity<?> eliminar(@PathVariable UUID misionId) {
        missions.eliminar(misionId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{misionId}/asignar/{dronId}")
    public ResponseEntity<?> asignar(@PathVariable UUID misionId, @PathVariable UUID dronId){
        missions.asignar(misionId, dronId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{misionId}/completar")
    public ResponseEntity<?> completar(@PathVariable UUID misionId, @RequestBody(required = false) CompletarReq body){
        missions.completar(misionId, body!=null? body.bateria_consumida_pct(): null);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{misionId}/fallar")
    public ResponseEntity<?> fallar(@PathVariable UUID misionId, @RequestBody(required = false) FallarReq body){
        missions.fallar(misionId, body!=null? body.motivo(): null);
        return ResponseEntity.ok().build();
    }
}