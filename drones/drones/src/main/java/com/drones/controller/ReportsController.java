package com.drones.controller;

import com.drones.service.ReportsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/reportes")
public class ReportsController {
    private final ReportsService reports;
    public ReportsController(ReportsService reports){ this.reports = reports; }

    @PostMapping("/resumen/refresh")
    public ResponseEntity<?> refresh(){ reports.refreshResumen(); return ResponseEntity.ok().build(); }

    @GetMapping("/resumen")
    public ResponseEntity<?> resumen(){ return ResponseEntity.ok(reports.resumen()); }
}
