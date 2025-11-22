package com.drones.service;

import com.drones.dto.DroneDtos; // Importar el DTO
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class DroneService {
    private final JdbcTemplate jdbc;
    public DroneService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public List<Map<String,Object>> listar() {
        return jdbc.queryForList("""
            SELECT id, modelo, estado, bateria_pct,
                   COALESCE(ST_Y(pos::geometry), NULL) AS ultima_lat,
                   COALESCE(ST_X(pos::geometry), NULL) AS ultima_lon
            FROM drones_db.drones
            ORDER BY modelo
        """);
    }

    // --- NUEVO MÉTODO ---
    public UUID crear(DroneDtos.CrearDronReq req) {
        // Insertamos el nuevo dron.
        // 'id' se genera automático (uuid_generate_v4 en DB).
        // 'estado' por defecto 'Disponible'.
        // 'bateria_pct' por defecto 100.
        String sql = """
            INSERT INTO drones_db.drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
            VALUES (?, ?, ?, 'Disponible', 100)
            RETURNING id
        """;

        return jdbc.queryForObject(sql, UUID.class,
                req.modelo(),
                req.capacidad_kg(),
                req.autonomia_min()
        );
    }
    // --------------------
}