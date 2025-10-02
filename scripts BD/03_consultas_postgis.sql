-- 03_consultas_postgis.sql
SET search_path TO drones_db, public;

-- 1) Total de horas por modelo (último mes)
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

-- 2) Top-5 drones con más Fallida
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

-- 3) Completadas por tipo para los dos modelos más usados
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

-- 4) 3 misiones más largas con consumo < p20 de las misiones más cortas
--    (consumo en % POSITIVO = MAX(bat) - MIN(bat) con signo invertido si tu telemetría baja)
WITH agg AS (
  SELECT m.id,
         EXTRACT(EPOCH FROM (COALESCE(m.fin,NOW()) - m.inicio))/60.0 AS min_dur,
         (MIN(rv.bateria_pct) - MAX(rv.bateria_pct)) * -1 AS consumo_pct -- => positivo si la batería va bajando
  FROM misiones m
  JOIN registro_vuelo rv ON rv.mision_id = m.id
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
SELECT id, ROUND(min_dur::numeric,1) AS dur_min, ROUND(consumo_pct::numeric,1) AS consumo_pct
FROM agg, thr
WHERE agg.consumo_pct < thr.consumo_p20
ORDER BY min_dur DESC
LIMIT 3;

-- 5) Promedio semanal por mes (último año) + delta
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

-- 8) Drones inactivos 30 días
WITH ult AS (
  SELECT d.id, d.modelo, d.estado, MAX(m.inicio) AS ultima_mision
  FROM drones d
  LEFT JOIN misiones m ON m.dron_id = d.id
  GROUP BY d.id, d.modelo, d.estado
)
SELECT id, modelo, estado, ultima_mision
FROM ult
WHERE ultima_mision IS NULL OR ultima_mision < NOW() - INTERVAL '30 days'
ORDER BY ultima_mision NULLS FIRST;

-- 9) 5 drones más cercanos a un POI (último mes)
WITH poi AS (
  SELECT ST_SetSRID(ST_MakePoint(-70.66,-33.45),4326)::geography AS g
),
dist AS (
  SELECT rv.dron_id, MIN(ST_Distance(rv.pos, p.g)) AS min_m
  FROM registro_vuelo rv
  CROSS JOIN poi p
  WHERE rv.ts >= NOW() - INTERVAL '1 month'
  GROUP BY rv.dron_id
)
SELECT dron_id, ROUND(min_m::numeric,2) AS distancia_min_m
FROM dist
ORDER BY min_m
LIMIT 5;

-- 10) Resumen MV
SELECT * FROM resumen_misiones_completadas ORDER BY tipo;


SET search_path TO drones_db, public;
SELECT id, nombre, email, rol, password_hash
FROM usuarios
WHERE email IN ('admin@drones.local','op1@drones.local');
