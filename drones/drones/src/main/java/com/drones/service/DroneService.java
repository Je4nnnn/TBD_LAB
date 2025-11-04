package com.drones.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

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
}
