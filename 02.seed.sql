-- 02_seed.sql  (dronesdb)
-- Inserta datos de ejemplo y refresca la MV de forma segura.

SET search_path TO drones_db, public;

-- =========================
-- 1) Usuarios (2 registros)
-- =========================
-- Password de ambos: 'admin123' (hash bcrypt solo para demo)
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES
 ('Admin',        'admin@drones.local',   '$2a$10$GX0bHkq0XlY7r9EmG6m8e8j3q2gmXj3Xp9g36n8x2L3o7Ho18tQK', 'ADMIN'),
 ('Operador Uno', 'op1@drones.local',     '$2a$10$s6Q5c3tB0HjKQxX1Y7r9EmG6m8e8j3q2gmXj3Xp9g36n8x2L3o7Ho18tQK', 'OPERADOR')
ON CONFLICT (email) DO NOTHING;

-- =======================
-- 2) Drones (5 registros)
-- =======================
-- Guardamos los ids generados en una tabla temporal
CREATE TEMP TABLE dr_sel (id uuid) ON COMMIT DROP;

WITH ins AS (
  INSERT INTO drones (id, modelo, capacidad_kg, autonomia_min, estado, bateria_pct, ultima_lat, ultima_lon)
  VALUES
    (uuid_generate_v4(),'DJI-M380', 2.5, 45, 'Disponible', 100, NULL, NULL),
    (uuid_generate_v4(),'Skydio-X2', 1.2, 35, 'Disponible', 100, NULL, NULL),
    (uuid_generate_v4(),'Anafi-A1', 1.8, 40, 'Disponible', 100, NULL, NULL),
    (uuid_generate_v4(),'DJI-Mini3',0.25, 30, 'Disponible', 100, NULL, NULL),
    (uuid_generate_v4(),'Mavic-3E', 0.8, 40, 'Disponible', 100, NULL, NULL)
  RETURNING id
)
INSERT INTO dr_sel (id)
SELECT id FROM ins;

-- Tomamos 2 ids para misiones de prueba
CREATE TEMP TABLE dr_a AS SELECT id FROM dr_sel LIMIT 1;
CREATE TEMP TABLE dr_b AS SELECT id FROM dr_sel OFFSET 1 LIMIT 1;

-- =========================
-- 3) Misiones (5 registros)
-- =========================
INSERT INTO misiones (id, dron_id, tipo,  estado,        inicio,                              fin,                                ruta_planeada)
VALUES
 -- Completada (aporta datos a la MV)
 (uuid_generate_v4(), (SELECT id FROM dr_a), 'Inspección', 'Completada',  now() - interval '55 minutes', now() - interval '30 minutes',
  '{"waypoints":[[-33.45,-70.66],[-33.44,-70.65]]}'),

 -- Pendiente
 (uuid_generate_v4(), (SELECT id FROM dr_b), 'Entrega',    'Pendiente',   NULL,                               NULL,
  '{"waypoints":[[-33.46,-70.61],[-33.47,-70.60]]}'),

 -- Pendiente
 (uuid_generate_v4(), (SELECT id FROM dr_a), 'Vigilancia', 'Pendiente',   NULL,                               NULL,
  '{"waypoints":[[-33.43,-70.64],[-33.44,-70.63]]}'),

 -- En Progreso (tendrá telemetría)
 (uuid_generate_v4(), (SELECT id FROM dr_b), 'Inspección', 'En Progreso', now() - interval '10 minutes',      NULL,
  '{"waypoints":[[-33.47,-70.67],[-33.48,-70.66]]}'),

 -- Pendiente sin dron asignado
 (uuid_generate_v4(), NULL,               'Inspección', 'Pendiente',   NULL,                               NULL,
  '{"waypoints":[[-33.49,-70.62],[-33.50,-70.60]]}');

-- ==========================================
-- 4) Telemetría para la misión "En Progreso"
-- ==========================================
DO $$
DECLARE m_en_progreso uuid;
BEGIN
  SELECT id INTO m_en_progreso
    FROM misiones
   WHERE estado='En Progreso'
   ORDER BY inicio DESC
   LIMIT 1;

  IF m_en_progreso IS NOT NULL THEN
    INSERT INTO registro_vuelo (mision_id, dron_id, ts, lat, lon, bateria_pct)
    SELECT m.id, m.dron_id,
           now() - (i || ' minutes')::interval,
           -33.4700 + i*0.0003, -70.6700 + i*0.0003,
           GREATEST(1, 100 - i)           -- no baja de 1%
    FROM generate_series(0, 5) AS g(i)
    JOIN misiones m ON m.id = m_en_progreso;
  END IF;
END $$;

-- =======================================================
-- 5) Refresco “a prueba de balas” de la MV de resumen
-- =======================================================
DO $$
DECLARE populated boolean;
BEGIN
  SELECT ispopulated
    INTO populated
    FROM pg_matviews
   WHERE schemaname = 'drones_db'
     AND matviewname = 'resumen_misiones_completadas';

  IF COALESCE(populated, false) = false THEN
    -- Primera vez: poblar sin concurrente
    EXECUTE 'REFRESH MATERIALIZED VIEW drones_db.resumen_misiones_completadas';
  ELSE
    -- Siguientes: refresco concurrente
    EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY drones_db.resumen_misiones_completadas';
  END IF;
END $$;

-- =========================
-- 6) Comprobaciones rápidas
-- =========================
SELECT  *   FROM usuarios;
SELECT drones     FROM drones;
SELECT misiones   FROM misiones;
SELECT * FROM resumen_misiones_completadas ORDER BY tipo;




-- 1) Habilita pgcrypto (una vez)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2) Re-hash para el usuario admin con bcrypt (cost 10)
UPDATE drones_db.usuarios
SET password_hash = crypt('admin123', gen_salt('bf', 10))
WHERE email = 'admin@drones.local';

-- 3) Verifica
SELECT nombre,email, password_hash FROM drones_db.usuarios WHERE email = 'admin@drones.local';
