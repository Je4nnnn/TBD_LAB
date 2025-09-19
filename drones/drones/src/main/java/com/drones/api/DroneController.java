package com.drones.api;

import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/drones")
public class DroneController {
    private final JdbcTemplate jdbc;
    public DroneController(JdbcTemplate jdbc){ this.jdbc = jdbc; }

    @GetMapping
    public List<Map<String,Object>> list(){
        // Derivamos lat/lon desde la geometría 'pos' (Opción B)
        return jdbc.queryForList("""
            SELECT id,
                   modelo,
                   estado,
                   bateria_pct,
                   ST_Y(pos::geometry) AS ultima_lat,
                   ST_X(pos::geometry) AS ultima_lon
              FROM drones_db.drones
             ORDER BY modelo
        """);
    }
}
