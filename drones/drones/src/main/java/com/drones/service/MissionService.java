package com.drones.service;

import com.drones.dto.MissionDtos;
import com.drones.repository.db.MissionDao;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class MissionService {
    private final MissionDao missions;
    public MissionService(MissionDao missions) { this.missions = missions; }

    public List<Map<String,Object>> listar() { return missions.listar(); }

    // --- NUEVO MÉTODO ---
    public UUID crear(MissionDtos.CrearReq req) {
        return missions.crear(req.tipo(), req.ruta_json());
    }
    // --------------------

    public void asignar(UUID misionId, UUID dronId) { missions.asignar(misionId, dronId); }

    public void completar(UUID misionId, Integer bateriaConsumida) {
        missions.completar(misionId, bateriaConsumida);
    }

    public void fallar(UUID misionId, String motivo) {
        missions.fallar(misionId, motivo);
    }

    public void registrarTelemetria(MissionDtos.TelemetriaReq r) {
        missions.registrarTelemetria(
                r.misionId(),
                r.ts() != null ? r.ts() : Instant.now(),
                r.lat(), r.lon(), r.alt_m(), r.bateria_pct(), r.vel_mps()
        );
    }
}