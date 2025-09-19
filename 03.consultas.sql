-- 03_consultas.sql
SET search_path TO drones_db;

-- 1) Duración de vuelo por modelo (último mes)
WITH m AS (
  SELECT d.modelo,
         EXTRACT(EPOCH FROM (COALESCE(mi.fin, NOW()) - mi.inicio))/3600.0 AS horas
  FROM misiones mi
  JOIN drones d ON d.id = mi.dron_id
  WHERE mi.inicio >= (DATE_TRUNC('month', NOW()) - INTERVAL '1 month')
    AND mi.estado = 'Completada'
)
SELECT modelo, ROUND(SUM(horas)::numeric, 2) AS horas_totales
FROM m
GROUP BY modelo
ORDER BY horas_totales DESC;

-- 2) Top-5 drones con más 'Fallida'
WITH cte AS (
  SELECT dron_id, COUNT(*) AS fallas
  FROM misiones
  WHERE estado = 'Fallida'
  GROUP BY dron_id
)
SELECT dron_id, fallas
FROM cte
ORDER BY fallas DESC
LIMIT 5;

-- 3) Comparación por tipo (dos modelos más usados)
WITH usados AS (
  SELECT d.modelo, COUNT(*) c
  FROM misiones m JOIN drones d ON d.id = m.dron_id
  GROUP BY d.modelo
  ORDER BY c DESC
  LIMIT 2
),
base AS (
  SELECT u.modelo, m.tipo
  FROM misiones m
  JOIN drones d ON d.id = m.dron_id
  JOIN usados u ON u.modelo = d.modelo
  WHERE m.estado = 'Completada'
)
SELECT tipo,
       SUM(CASE WHEN modelo = (SELECT modelo FROM usados OFFSET 0 LIMIT 1) THEN 1 ELSE 0 END) AS modelo_A,
       SUM(CASE WHEN modelo = (SELECT modelo FROM usados OFFSET 1 LIMIT 1) THEN 1 ELSE 0 END) AS modelo_B
FROM base
GROUP BY tipo
ORDER BY tipo;

-- 4) 3 misiones más largas con consumo < p20 de las más cortas
WITH agg AS (
  SELECT m.id,
         EXTRACT(EPOCH FROM (COALESCE(m.fin,NOW()) - m.inicio))/60.0 AS min_dur,
         (MAX(rv.bateria_pct) - MIN(rv.bateria_pct)) * -1 AS consumo_pct
  FROM misiones m
  JOIN registro_vuelo rv ON rv.mision_id = m.id
  GROUP BY m.id
),
pct_short AS (
  SELECT PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY consumo_pct) AS p20
  FROM agg
  WHERE min_dur <= (SELECT PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY min_dur) FROM agg)
)
SELECT id, ROUND(min_dur::numeric,1) AS dur_min, consumo_pct
FROM agg, pct_short
WHERE consumo_pct < p20
ORDER BY min_dur DESC
LIMIT 3;

-- 5) Promedio semanal por mes (último año) + delta mes anterior
WITH meses AS (
  SELECT DATE_TRUNC('month', d)::date AS mes
  FROM GENERATE_SERIES(DATE_TRUNC('month', NOW()) - INTERVAL '11 months',
                       DATE_TRUNC('month', NOW()), interval '1 month') d
),
m_comp AS (
  SELECT DATE_TRUNC('month', inicio)::date AS mes, COUNT(*) AS total
  FROM misiones
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
ORDER BY w.mes;

-- 6) SP asignar_mision_a_dron → definido en 01_schema.sql

-- 7) SP poner_mantenimiento_por_modelo → definido en 01_schema.sql

-- 8) Drones inactivos últimos 30 días
WITH ult AS (
  SELECT d.id, d.modelo, d.estado,
         MAX(m.inicio) AS ultima_mision
  FROM drones d
  LEFT JOIN misiones m ON m.dron_id = d.id
  GROUP BY d.id, d.modelo, d.estado
)
SELECT id, modelo, estado, ultima_mision
FROM ult
WHERE ultima_mision IS NULL OR ultima_mision < NOW() - INTERVAL '30 days'
ORDER BY ultima_mision NULLS FIRST;

-- 9) 5 drones más cercanos a un punto (último mes)
WITH params AS (SELECT (-33.45)::double precision AS lat0, (-70.66)::double precision AS lon0),
dist AS (
  SELECT rv.dron_id,
         MIN(
           2 * 6371000 * ASIN(
               SQRT(
                 POWER(SIN(RADIANS((rv.lat - p.lat0)/2)),2) +
                 COS(RADIANS(p.lat0)) * COS(RADIANS(rv.lat)) *
                 POWER(SIN(RADIANS((rv.lon - p.lon0)/2)),2)
               )
           )
         ) AS min_m
  FROM registro_vuelo rv
  CROSS JOIN params p
  WHERE rv.ts >= NOW() - INTERVAL '1 month'
  GROUP BY rv.dron_id
)
SELECT dron_id, ROUND(min_m::numeric,2) AS distancia_min_m
FROM dist
ORDER BY min_m ASC
LIMIT 5;

-- 10) Consulta de la MV + refresco
SELECT * FROM resumen_misiones_completadas ORDER BY tipo;
-- Para refrescarla en producción de forma no bloqueante:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY resumen_misiones_completadas;


SELECT email, rol FROM drones_db.usuarios;

