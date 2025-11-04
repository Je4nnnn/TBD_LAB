-- 02_seed_postgis.sql  (dronesdb)
-- Ejecuta después de 01_schema_postgis.sql
SET search_path TO drones_db, public;

-- =========================
-- 1) Usuarios (2 registros)
-- =========================
-- Password de ambos: 'admin123' (hash bcrypt DEMO)
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES
 ('Admin',        'admin@drones.local', '$2a$10$GX0bHkq0XlY7r9EmG6m8e8j3q2gmXj3Xp9g36n8x2L3o7Ho18tQK', 'ADMIN'),
 ('Operador Uno', 'op1@drones.local',   '$2a$10$GX0bHkq0XlY7r9EmG6m8e8j3q2gmXj3Xp9g36n8x2L3o7Ho18tQK', 'OPERADOR')
ON CONFLICT (email) DO NOTHING;

-- =======================
-- 2) Drones (6 registros)
-- =======================
INSERT INTO drones (id, modelo, capacidad_kg, autonomia_min, estado, bateria_pct, pos)
VALUES
  (uuid_generate_v4(),'DJI-M380',  2.5, 45, 'Disponible', 100, ST_SetSRID(ST_MakePoint(-70.6600,-33.4500),4326)::geography),
  (uuid_generate_v4(),'Skydio-X2', 1.2, 35, 'Disponible', 100, ST_SetSRID(ST_MakePoint(-70.6650,-33.4520),4326)::geography),
  (uuid_generate_v4(),'Anafi-A1',  1.8, 40, 'Disponible', 100, NULL),
  (uuid_generate_v4(),'DJI-Mini3', 0.25,30, 'Disponible', 100, NULL),
  (uuid_generate_v4(),'Mavic-3E',  0.8, 40, 'Disponible', 100, ST_SetSRID(ST_MakePoint(-70.6550,-33.4480),4326)::geography),
  (uuid_generate_v4(),'Evo-II',    2.0, 35, 'Disponible', 100, NULL);

-- Tomamos 3 drones distintos y estables por modelo/id (no usamos creado_en)
DO $$
DECLARE d1 uuid; d2 uuid; d3 uuid;
BEGIN
  SELECT id INTO d1 FROM drones ORDER BY modelo, id LIMIT 1;
  SELECT id INTO d2 FROM drones ORDER BY modelo, id OFFSET 1 LIMIT 1;
  SELECT id INTO d3 FROM drones ORDER BY modelo, id OFFSET 2 LIMIT 1;

  -- =========================
  -- 3) Misiones (8 registros)
  -- =========================

  -- Completada #1
  INSERT INTO misiones (id, dron_id, tipo, estado, inicio, fin, ruta_planeada, bateria_consumida_pct)
  VALUES (uuid_generate_v4(), d1, 'Inspección', 'Completada',
          now() - interval '2 hours', now() - interval '70 minutes',
          '{"waypoints":[[-33.455,-70.665],[-33.449,-70.660],[-33.446,-70.658]]}',
          27);

  -- Completada #2
  INSERT INTO misiones (id, dron_id, tipo, estado, inicio, fin, ruta_planeada, bateria_consumida_pct)
  VALUES (uuid_generate_v4(), d2, 'Entrega', 'Completada',
          now() - interval '90 minutes', now() - interval '20 minutes',
          '{"waypoints":[[-33.470,-70.670],[-33.468,-70.668],[-33.466,-70.666]]}',
          34);

  -- En Progreso #1 (tendrá telemetría)
  INSERT INTO misiones (id, dron_id, tipo, estado, inicio, fin, ruta_planeada)
  VALUES (uuid_generate_v4(), d3, 'Inspección', 'En Progreso',
          now() - interval '25 minutes', NULL,
          '{"waypoints":[[-33.471,-70.671],[-33.472,-70.670],[-33.473,-70.669]]}');

  -- En Progreso #2 (tendrá telemetría)
  INSERT INTO misiones (id, dron_id, tipo, estado, inicio, fin, ruta_planeada)
  VALUES (uuid_generate_v4(), d2, 'Vigilancia', 'En Progreso',
          now() - interval '12 minutes', NULL,
          '{"waypoints":[[-33.440,-70.640],[-33.441,-70.639],[-33.442,-70.638]]}');

  -- Pendiente (asignable)
  INSERT INTO misiones (id, dron_id, tipo, estado, inicio, fin, ruta_planeada)
  VALUES (uuid_generate_v4(), d1, 'Entrega', 'Pendiente',
          NULL, NULL,
          '{"waypoints":[[-33.450,-70.660],[-33.451,-70.659]]}');

  -- Pendiente (asignable)
  INSERT INTO misiones (id, dron_id, tipo, estado, inicio, fin, ruta_planeada)
  VALUES (uuid_generate_v4(), d3, 'Inspección', 'Pendiente',
          NULL, NULL,
          '{"waypoints":[[-33.444,-70.652],[-33.443,-70.651]]}');

  -- Fallida
  INSERT INTO misiones (id, dron_id, tipo, estado, inicio, fin, ruta_planeada)
  VALUES (uuid_generate_v4(), d1, 'Vigilancia', 'Fallida',
          now() - interval '3 hours', now() - interval '2 hours 15 minutes',
          '{"waypoints":[[-33.460,-70.668],[-33.459,-70.667]]}');

  -- Pendiente sin dron
  INSERT INTO misiones (id, dron_id, tipo, estado, inicio, fin, ruta_planeada)
  VALUES (uuid_generate_v4(), NULL, 'Inspección', 'Pendiente', NULL, NULL,
          '{"waypoints":[[-33.452,-70.662],[-33.453,-70.661]]}');
END $$;

-- ==========================================
-- 4) Telemetría para las 2 misiones en progreso
-- ==========================================
DO $$
DECLARE m1 uuid; m2 uuid;
BEGIN
  SELECT id INTO m1 FROM misiones WHERE estado='En Progreso'
  ORDER BY inicio ASC LIMIT 1;

  SELECT id INTO m2 FROM misiones WHERE estado='En Progreso'
  ORDER BY inicio DESC LIMIT 1;

  -- Misión en progreso #1
  IF m1 IS NOT NULL THEN
    INSERT INTO registro_vuelo (mision_id, dron_id, ts, lat, lon, alt_m, bateria_pct, vel_mps)
    SELECT m.id, m.dron_id,
           now() - (i || ' minutes')::interval,
           -33.4710 + i*0.00025, -70.6710 + i*0.00025,
           100 + i*2, GREATEST(1, 95 - i*2), 10 + i
    FROM generate_series(0, 8) AS g(i)
    JOIN misiones m ON m.id = m1;
  END IF;

  -- Misión en progreso #2
  IF m2 IS NOT NULL THEN
    INSERT INTO registro_vuelo (mision_id, dron_id, ts, lat, lon, alt_m, bateria_pct, vel_mps)
    SELECT m.id, m.dron_id,
           now() - (i || ' minutes')::interval,
           -33.4400 + i*0.00020, -70.6400 + i*0.00020,
           80 + i*1.5, GREATEST(1, 88 - i*1), 8 + i*0.8
    FROM generate_series(0, 10) AS g(i)
    JOIN misiones m ON m.id = m2;
  END IF;
END $$;

-- =======================================================
-- 5) Refrescar MV de resumen (primera vez vs posteriores)
-- =======================================================
DO $$
DECLARE populated boolean;
BEGIN
  SELECT ispopulated INTO populated
  FROM pg_matviews
  WHERE schemaname='drones_db' AND matviewname='resumen_misiones_completadas';

  IF COALESCE(populated,false) = false THEN
    EXECUTE 'REFRESH MATERIALIZED VIEW drones_db.resumen_misiones_completadas';
  ELSE
    EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY drones_db.resumen_misiones_completadas';
  END IF;
END $$;

-- =========================
-- 6) Chequeos rápidos
-- =========================
-- Quita los comentarios si quieres ver resultados al final del seed:
--SELECT * FROM usuarios;
-- SELECT id, modelo, estado, bateria_pct, ST_Y(pos::geometry) AS lat, ST_X(pos::geometry) AS lon FROM drones ORDER BY modelo;
-- SELECT * FROM misiones ORDER BY creado_en DESC;
-- SELECT * FROM resumen_misiones_completadas ORDER BY tipo;


SET search_path TO drones_db, public;
SELECT id, nombre, email, rol,password_hash FROM usuarios WHERE email IN ('admin@drones.local','op1@drones.local');






----USAR ESTOOOO PARA PONER UNA MISION EN PENDIENTEEEE

-- usa gen_random_uuid() (pgcrypto). Si no lo tienes, más abajo te dejo alternativa.
INSERT INTO misiones (id, tipo, estado, inicio, fin, dron_id, ruta_planeada)
VALUES (
  gen_random_uuid(),
  'Inspección',
  'Pendiente',
  NULL,
  NULL,
  NULL,
  jsonb_build_object(
    'waypoints',
    jsonb_build_array(
      jsonb_build_array(-33.45, -70.66),
      jsonb_build_array(-33.46, -70.67),
      jsonb_build_array(-33.47, -70.68)
    )
  )
)
RETURNING id, tipo, estado;

