package com.drones.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class ReportsService {
    private final JdbcTemplate jdbc;
    public ReportsService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    // --- PREGUNTA 10: Ya existente ---
    public void refreshResumen() {
        jdbc.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY drones_db.resumen_misiones_completadas");
    }
    public List<Map<String,Object>> resumen() {
        return jdbc.queryForList("SELECT * FROM drones_db.resumen_misiones_completadas ORDER BY tipo");
    }

    // --- PREGUNTA 1: Duración de Vuelo ---
    public List<Map<String,Object>> horasPorModelo() {
        return jdbc.queryForList("""
            WITH m AS (
              SELECT d.modelo,
                     EXTRACT(EPOCH FROM (COALESCE(mi.fin, NOW()) - mi.inicio))/3600.0 AS horas
              FROM drones_db.misiones mi
              JOIN drones_db.drones d ON d.id = mi.dron_id
              WHERE mi.inicio >= (DATE_TRUNC('month', NOW()) - INTERVAL '1 month')
                AND mi.estado IN ('Completada', 'En Progreso', 'Fallida')
            )
            SELECT modelo, ROUND(SUM(horas)::numeric, 2) AS horas_totales
            FROM m
            GROUP BY modelo
            ORDER BY horas_totales DESC
        """);
    }

    // --- PREGUNTA 2: Fallos Recurrentes ---
    public List<Map<String,Object>> fallasRecurrentes() {
        return jdbc.queryForList("""
            WITH cte AS (
              SELECT dron_id, COUNT(*) AS fallas
              FROM drones_db.misiones
              WHERE estado = 'Fallida'
              GROUP BY dron_id
            )
            SELECT c.dron_id, d.modelo, c.fallas
            FROM cte c
            JOIN drones_db.drones d ON d.id = c.dron_id
            ORDER BY c.fallas DESC
            LIMIT 5
        """);
    }

    // --- PREGUNTA 3: Comparación de Desempeño ---
    public List<Map<String,Object>> comparacionModelos() {
        return jdbc.queryForList("""
            WITH usados AS (
              SELECT d.modelo, COUNT(*) c
              FROM drones_db.misiones m JOIN drones_db.drones d ON d.id = m.dron_id
              GROUP BY d.modelo
              ORDER BY c DESC
              LIMIT 2
            ),
            base AS (
              SELECT u.modelo, m.tipo
              FROM drones_db.misiones m
              JOIN drones_db.drones d ON d.id = m.dron_id
              JOIN usados u ON u.modelo = d.modelo
              WHERE m.estado = 'Completada'
            )
            SELECT tipo,
                   SUM(CASE WHEN modelo = (SELECT modelo FROM usados OFFSET 0 LIMIT 1) THEN 1 ELSE 0 END) AS modelo_a_count,
                   (SELECT modelo FROM usados OFFSET 0 LIMIT 1) as modelo_a_name,
                   SUM(CASE WHEN modelo = (SELECT modelo FROM usados OFFSET 1 LIMIT 1) THEN 1 ELSE 0 END) AS modelo_b_count,
                   (SELECT modelo FROM usados OFFSET 1 LIMIT 1) as modelo_b_name
            FROM base
            GROUP BY tipo
            ORDER BY tipo
        """);
    }

    // --- PREGUNTA 4: Patrones de Batería ---
    public List<Map<String,Object>> eficienciaBateria() {
        return jdbc.queryForList("""
            WITH agg AS (
              SELECT m.id, m.tipo,
                     EXTRACT(EPOCH FROM (COALESCE(m.fin,NOW()) - m.inicio))/60.0 AS min_dur,
                     (MIN(rv.bateria_pct) - MAX(rv.bateria_pct)) * -1 AS consumo_pct
              FROM drones_db.misiones m
              JOIN drones_db.registro_vuelo rv ON rv.mision_id = m.id
              GROUP BY m.id
            ),
            pct_short AS (
              SELECT PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY min_dur) AS dur_p20
              FROM agg
            ),
            base AS (
              SELECT a.*
              FROM agg a, pct_short p
              WHERE a.min_dur <= p.dur_p20
            ),
            thr AS (
              SELECT PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY consumo_pct) AS consumo_p20
              FROM base
            )
            SELECT agg.id, agg.tipo, ROUND(agg.min_dur::numeric,1) AS dur_min, ROUND(agg.consumo_pct::numeric,1) AS consumo_pct
            FROM agg, thr
            WHERE agg.consumo_pct < thr.consumo_p20
            ORDER BY agg.min_dur DESC
            LIMIT 3
        """);
    }

    // --- PREGUNTA 5: Promedio Mensual ---
    public List<Map<String,Object>> promedioMensual() {
        return jdbc.queryForList("""
            WITH meses AS (
              SELECT DATE_TRUNC('month', d)::date AS mes
              FROM GENERATE_SERIES(DATE_TRUNC('month', NOW()) - INTERVAL '11 months',
                                   DATE_TRUNC('month', NOW()), interval '1 month') d
            ),
            m_comp AS (
              SELECT DATE_TRUNC('month', inicio)::date AS mes, COUNT(*) AS total
              FROM drones_db.misiones
              WHERE estado='Completada' AND inicio >= (DATE_TRUNC('month', NOW()) - INTERVAL '12 months')
              GROUP BY 1
            ),
            weeks AS (
              SELECT m.mes, CEIL(EXTRACT(DAY FROM (m.mes + INTERVAL '1 month - 1 day'))/7.0)::int AS semanas_aprox
              FROM meses m
            )
            SELECT w.mes,
                   COALESCE(c.total,0) AS completas,
                   ROUND(COALESCE(c.total,0) / NULLIF(w.semanas_aprox,0)::numeric, 2) AS prom_semanal,
                   ROUND(
                     (COALESCE(c.total,0) / NULLIF(w.semanas_aprox,0)::numeric)
                     - LAG(COALESCE(c.total,0) / NULLIF(w.semanas_aprox,0)::numeric) OVER (ORDER BY w.mes),
                     2
                   ) AS delta_vs_mes_ant
            FROM weeks w
            LEFT JOIN m_comp c ON c.mes = w.mes
            ORDER BY w.mes DESC
        """);
    }

    // --- PREGUNTA 7: Procedimiento Almacenado (Actualización Masiva) ---
    public void ejecutarMantenimiento(String modelo) {
        jdbc.execute("CALL drones_db.poner_mantenimiento_por_modelo('" + modelo + "')");
    }

    // --- PREGUNTA 8: Drones Inactivos ---
    public List<Map<String,Object>> dronesInactivos() {
        return jdbc.queryForList("""
            WITH ult AS (
              SELECT d.id, d.modelo, d.estado, MAX(m.inicio) AS ultima_mision
              FROM drones_db.drones d
              LEFT JOIN drones_db.misiones m ON m.dron_id = d.id
              GROUP BY d.id, d.modelo, d.estado
            )
            SELECT id, modelo, estado, ultima_mision
            FROM ult
            WHERE ultima_mision IS NULL OR ultima_mision < NOW() - INTERVAL '30 days'
            ORDER BY ultima_mision NULLS FIRST
        """);
    }

    // --- PREGUNTA 9: Análisis Geográfico (POI fijo por ejemplo) ---
    public List<Map<String,Object>> cercaPOI() {
        // Usamos el punto (-70.66, -33.45) como ejemplo
        return jdbc.queryForList("""
            WITH poi AS (
              SELECT ST_SetSRID(ST_MakePoint(-70.66,-33.45),4326)::geography AS g
            ),
            dist AS (
              SELECT rv.dron_id, MIN(ST_Distance(rv.pos, p.g)) AS min_m
              FROM drones_db.registro_vuelo rv
              CROSS JOIN poi p
              WHERE rv.ts >= NOW() - INTERVAL '1 month'
              GROUP BY rv.dron_id
            )
            SELECT d.dron_id, dr.modelo, ROUND(d.min_m::numeric,2) AS distancia_min_m
            FROM dist d
            JOIN drones_db.drones dr ON dr.id = d.dron_id
            ORDER BY d.min_m
            LIMIT 5
        """);
    }
}