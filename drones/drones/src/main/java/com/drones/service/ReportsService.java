package com.drones.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class ReportsService {
    private final JdbcTemplate jdbc;
    public ReportsService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public void refreshResumen() {
        jdbc.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY drones_db.resumen_misiones_completadas");
    }

    public List<Map<String,Object>> resumen() {
        return jdbc.queryForList("SELECT * FROM drones_db.resumen_misiones_completadas ORDER BY tipo");
    }
}
