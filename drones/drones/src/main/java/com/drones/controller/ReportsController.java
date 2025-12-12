package com.drones.controller;

import com.drones.service.ReportsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/reportes")
public class ReportsController {
    private final ReportsService reports;
    public ReportsController(ReportsService reports){ this.reports = reports; }

    @PostMapping("/resumen/refresh")
    public ResponseEntity<?> refresh(){ reports.refreshResumen(); return ResponseEntity.ok().build(); }

    @GetMapping("/resumen")
    public ResponseEntity<?> resumen(){ return ResponseEntity.ok(reports.resumen()); }

    // --- NUEVOS ENDPOINTS ---

    @GetMapping("/horas-vuelo")
    public ResponseEntity<?> horasVuelo() { return ResponseEntity.ok(reports.horasPorModelo()); }

    @GetMapping("/fallas-recurrentes")
    public ResponseEntity<?> fallasRecurrentes() { return ResponseEntity.ok(reports.fallasRecurrentes()); }

    @GetMapping("/comparacion-modelos")
    public ResponseEntity<?> comparacionModelos() { return ResponseEntity.ok(reports.comparacionModelos()); }

    @GetMapping("/eficiencia-bateria")
    public ResponseEntity<?> eficienciaBateria() { return ResponseEntity.ok(reports.eficienciaBateria()); }

    @GetMapping("/promedio-mensual")
    public ResponseEntity<?> promedioMensual() { return ResponseEntity.ok(reports.promedioMensual()); }

    @GetMapping("/inactivos")
    public ResponseEntity<?> inactivos() { return ResponseEntity.ok(reports.dronesInactivos()); }

    @GetMapping("/cerca-poi")
    public ResponseEntity<?> cercaPoi() { return ResponseEntity.ok(reports.cercaPOI()); }

    @PostMapping("/mantenimiento")
    public ResponseEntity<?> triggerMantenimiento(@RequestBody Map<String,String> body) {
        String modelo = body.get("modelo");
        reports.ejecutarMantenimiento(modelo);
        return ResponseEntity.ok(Map.of("mensaje", "Procedimiento ejecutado para " + modelo));
    }
}