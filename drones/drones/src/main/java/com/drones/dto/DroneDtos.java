package com.drones.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public final class DroneDtos {

    public record CrearDronReq(
            @NotBlank String modelo,
            @NotNull @Min(0) Double capacidad_kg,
            @NotNull @Min(0) Integer autonomia_min,
            Double lat,
            Double lon
    ) {}

    private DroneDtos() {}
}