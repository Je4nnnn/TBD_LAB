package com.drones.dto;

import java.util.List;
import java.util.UUID;

public final class OptimizationDtos {
    public record RutaReq(List<UUID> misiones) {}
    public record Paso(UUID misionId, double lat, double lon, double dist_m) {}
    public record RutaRes(List<Paso> orden, double distancia_total_m) {}
    private OptimizationDtos() {}
}
