package com.drones.api;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/optimizacion")
public class OptimizationController {

    private final JdbcTemplate jdbc;
    public OptimizationController(JdbcTemplate jdbc){ this.jdbc = jdbc; }

    public record RutaReq(List<UUID> misiones){}
    public record Paso(UUID misionId, double lat, double lon, double dist_m){}
    public record RutaRes(List<Paso> orden, double distancia_total_m){}

    @PostMapping("/ruta")
    public RutaRes optimizar(@RequestBody RutaReq req){
        if (req.misiones()==null || req.misiones().isEmpty()) {
            return new RutaRes(List.of(), 0.0);
        }

        // 1) Punto representativo por misión:
        //    - último registro de vuelo si existe
        //    - si no, primer waypoint de ruta_planeada
        String sql = """
            WITH last_pos AS (
              SELECT m.id,
                     (SELECT rv.pos
                        FROM drones_db.registro_vuelo rv
                       WHERE rv.mision_id = m.id
                       ORDER BY rv.ts DESC
                       LIMIT 1) AS pos
                FROM drones_db.misiones m
               WHERE m.id = ANY(?)
            ),
            points AS (
              SELECT lp.id,
                     COALESCE(lp.pos,
                              ST_SetSRID(
                                ST_MakePoint(
                                  (m.ruta_planeada->'waypoints'->0->>1)::numeric,
                                  (m.ruta_planeada->'waypoints'->0->>0)::numeric
                                ),4326
                              )::geography
                     ) AS g
                FROM last_pos lp
                JOIN drones_db.misiones m ON m.id = lp.id
            )
            SELECT id,
                   ST_Y(g::geometry) AS lat,
                   ST_X(g::geometry) AS lon
              FROM points
            """;

        var rows = jdbc.queryForList(sql, (Object) req.misiones().toArray(UUID[]::new));
        Map<UUID, double[]> pts = new HashMap<>();
        for (var r : rows) {
            UUID id = (UUID) r.get("id");
            double lat = ((Number) r.get("lat")).doubleValue();
            double lon = ((Number) r.get("lon")).doubleValue();
            pts.put(id, new double[]{lat, lon});
        }

        // 2) Heurística NN (Nearest Neighbor) en memoria
        List<UUID> remaining = new ArrayList<>(pts.keySet());
        remaining.sort(Comparator.comparingDouble(u -> pts.get(u)[0])); // seed determinista
        UUID current = remaining.remove(0);
        double[] cur = pts.get(current);
        List<Paso> orden = new ArrayList<>();
        orden.add(new Paso(current, cur[0], cur[1], 0.0));
        double total = 0.0;

        while (!remaining.isEmpty()) {
            UUID best = null;
            double bestD = Double.MAX_VALUE;
            for (UUID cand : remaining) {
                double[] w = pts.get(cand);
                double d = haversine(cur[0], cur[1], w[0], w[1]);
                if (d < bestD) { bestD = d; best = cand; }
            }
            total += bestD;
            cur = pts.get(best);
            orden.add(new Paso(best, cur[0], cur[1], bestD));
            remaining.remove(best);
        }
        return new RutaRes(orden, total);
    }

    // Distancia Haversine (metros)
    private static double haversine(double lat1, double lon1, double lat2, double lon2){
        double R = 6371000.0;
        double dLat = Math.toRadians(lat2-lat1);
        double dLon = Math.toRadians(lon2-lon1);
        double a = Math.sin(dLat/2)*Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1))*Math.cos(Math.toRadians(lat2))*
                        Math.sin(dLon/2)*Math.sin(dLon/2);
        double c = 2*Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R*c;
    }
}
