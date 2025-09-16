package com.drones.api;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/reportes")
public class ReportsController {
    private final JdbcTemplate jdbc;
    public ReportsController(JdbcTemplate jdbc){ this.jdbc = jdbc; }

    @PostMapping("/resumen/refresh")
    public void refreshResumen(){
        jdbc.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY drones_db.resumen_misiones_completadas");
    }

    @GetMapping("/resumen")
    public List<Map<String,Object>> resumen(){
        return jdbc.queryForList("SELECT * FROM drones_db.resumen_misiones_completadas ORDER BY tipo");
    }
}
