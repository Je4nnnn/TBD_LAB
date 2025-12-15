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
            SELECT id, modelo, capacidad_kg, autonomia_min, estado, bateria_pct,
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
        String sql;
        Object[] params;
        if (req.lat() != null && req.lon() != null) {
            sql = """
                INSERT INTO drones_db.drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct, pos)
                VALUES (?, ?, ?, 'Disponible', 100, ST_SetSRID(ST_MakePoint(?, ?),4326)::geography)
                RETURNING id
            """;
            params = new Object[] {
                req.modelo(),
                req.capacidad_kg(),
                req.autonomia_min(),
                req.lon(),
                req.lat()
            };
        } else {
            sql = """
                INSERT INTO drones_db.drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
                VALUES (?, ?, ?, 'Disponible', 100)
                RETURNING id
            """;
            params = new Object[] {
                req.modelo(),
                req.capacidad_kg(),
                req.autonomia_min()
            };
        }
        return jdbc.queryForObject(sql, UUID.class, params);
    }
    // --------------------

    // Eliminar dron por id
    public void eliminar(UUID id) {
        try {
            int rows = jdbc.update("DELETE FROM drones_db.drones WHERE id = ?", id);
            if (rows == 0) {
                throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.NOT_FOUND, "Dron no encontrado");
            }
        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            throw new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.CONFLICT, 
                "No se puede eliminar el dron porque tiene misiones asociadas");
        }
    }
}