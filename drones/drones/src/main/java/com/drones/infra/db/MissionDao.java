package com.drones.infra.db;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Connection;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Repository
public class MissionDao {
    private final JdbcTemplate jdbc;
    public MissionDao(JdbcTemplate jdbc){ this.jdbc = jdbc; }

    public UUID crear(String tipo, String rutaPlaneadaJson){
        String sql = "INSERT INTO drones_db.misiones (tipo, estado, ruta_planeada) " +
                "VALUES (?,?,?::jsonb) RETURNING id";
        return jdbc.queryForObject(sql, UUID.class, tipo, "Pendiente", rutaPlaneadaJson);
    }

    public void asignar(UUID misionId, UUID dronId){
        jdbc.execute((Connection con) -> {
            try (var call = con.prepareCall("CALL drones_db.asignar_mision_a_dron(?,?)")) {
                call.setObject(1, misionId);
                call.setObject(2, dronId);
                call.execute();
            }
            return null;
        });
    }

    public void completar(UUID misionId, Integer bateriaConsumidaPct){
        jdbc.update("""
            UPDATE drones_db.misiones
               SET estado='Completada',
                   fin = COALESCE(fin, now()),
                   bateria_consumida_pct = COALESCE(?, bateria_consumida_pct)
             WHERE id = ?
        """, bateriaConsumidaPct, misionId);
    }

    public void fallar(UUID misionId, String motivo){
        jdbc.update("""
            UPDATE drones_db.misiones
               SET estado='Fallida',
                   fin = COALESCE(fin, now()),
                   motivo_fallo = COALESCE(?, motivo_fallo)
             WHERE id = ?
        """, motivo, misionId);
    }

    public List<Map<String,Object>> listar(){
        return jdbc.queryForList("""
            SELECT m.id, m.tipo, m.estado, m.inicio, m.fin, m.dron_id,
                   d.modelo AS dron_modelo,
                   m.bateria_consumida_pct, m.ruta_planeada, m.motivo_fallo
              FROM drones_db.misiones m
              LEFT JOIN drones_db.drones d ON d.id = m.dron_id
             ORDER BY m.creado_en DESC
        """);
    }

    public void registrarTelemetria(UUID misionId, Instant ts, double lat, double lon,
                                    Double alt, Integer bateria, Double vel){
        // 'pos' se genera automáticamente; incluimos dron_id desde la misión
        jdbc.update("""
            INSERT INTO drones_db.registro_vuelo
                (mision_id, dron_id, ts, lat, lon, alt_m, bateria_pct, vel_mps)
            SELECT ?, m.dron_id, ?, ?, ?, ?, ?, ?
              FROM drones_db.misiones m
             WHERE m.id = ?
        """,
                misionId,
                Timestamp.from(ts != null ? ts : Instant.now()),
                lat, lon, alt, bateria, vel,
                misionId);
    }
}
