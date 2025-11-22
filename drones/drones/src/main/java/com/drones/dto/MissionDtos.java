package com.drones.dto;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

public final class MissionDtos {
    // Agregamos este nuevo record para la creación
    public record CrearReq(String tipo, String ruta_json) {}

    public record CompletarReq(Integer bateria_consumida_pct) {}
    public record FallarReq(String motivo) {}
    public record TelemetriaReq(
            @NotNull UUID misionId,
            @NotNull Double lat,
            @NotNull Double lon,
            Double alt_m,
            Integer bateria_pct,
            Double vel_mps,
            Instant ts
    ) {}
    private MissionDtos() {}
}