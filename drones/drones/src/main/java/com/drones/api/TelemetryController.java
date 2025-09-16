package com.drones.api;

import com.drones.infra.db.MissionDao;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/telemetria")
public class TelemetryController {
    private final MissionDao dao;
    public TelemetryController(MissionDao dao){ this.dao = dao; }

    public record TelemetryReq(
            @NotBlank String misionId,
            Instant ts,
            @NotNull Double lat,
            @NotNull Double lon,
            Double alt_m,
            Integer bateria_pct,
            Double vel_mps
    ) {}

    @PostMapping
    public void ingest(@RequestBody TelemetryReq t){
        dao.registrarTelemetria(
                UUID.fromString(t.misionId()),
                t.ts()==null ? Instant.now() : t.ts(),
                t.lat(), t.lon(), t.alt_m(), t.bateria_pct(), t.vel_mps()
        );
    }
}
