package com.drones.controller;

import com.drones.dto.OptimizationDtos.RutaReq;
import com.drones.service.OptimizationService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/optimizacion")
public class OptimizationController {
    private final OptimizationService opt;
    public OptimizationController(OptimizationService opt){ this.opt = opt; }

    @PostMapping("/ruta")
    public ResponseEntity<?> ruta(@RequestBody @Valid RutaReq req){
        return ResponseEntity.ok(opt.optimizar(req));
    }
}
