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

















-- 04_seed_analytics_v2.sql
-- Ejecutar en dronesdb
SET search_path TO drones_db, public;

DO $$
DECLARE
    -- Variables para guardar IDs de drones creados
    d_fallas UUID;
    d_mant   UUID;
    d_bat    UUID;
    d_poi    UUID;
    d_old    UUID;
    d_modA   UUID;
    d_modB   UUID;
    
    -- Variable temporal para misiones
    m_id     UUID;
BEGIN

    -- ========================================================================
    -- 1. PREPARACIÓN DE DRONES (Modelos Específicos para las pruebas)
    -- ========================================================================
    
    -- Dron para Q2 (Fallas Recurrentes)
    INSERT INTO drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
    VALUES ('Crash-Master-2000', 5.0, 20, 'Disponible', 100) RETURNING id INTO d_fallas;

    -- Dron para Q7 (Mantenimiento > 100 horas)
    INSERT INTO drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
    VALUES ('Heavy-Lifter-3000', 10.0, 120, 'Disponible', 100) RETURNING id INTO d_mant;

    -- Dron para Q4 (Anomalía de batería: vuela mucho, gasta poco)
    INSERT INTO drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
    VALUES ('Tesla-Drone-X', 3.0, 60, 'Disponible', 100) RETURNING id INTO d_bat;

    -- Dron para Q9 (Cercano al POI -70.66, -33.45)
    INSERT INTO drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
    VALUES ('Spy-Eye-V1', 1.0, 30, 'Disponible', 100) RETURNING id INTO d_poi;

    -- Dron para Q8 (Inactivo > 30 días)
    INSERT INTO drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
    VALUES ('Old-Relic-99', 2.0, 40, 'Disponible', 100) RETURNING id INTO d_old;

    -- Drones para Q1 y Q3 (Comparación de Modelos populares)
    INSERT INTO drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
    VALUES ('DJI-M380', 2.5, 45, 'Disponible', 90) RETURNING id INTO d_modA;
    
    INSERT INTO drones (modelo, capacidad_kg, autonomia_min, estado, bateria_pct)
    VALUES ('Skydio-X2', 1.2, 35, 'Disponible', 85) RETURNING id INTO d_modB;


    -- ========================================================================
    -- 2. GENERACIÓN DE DATOS PARA LAS PREGUNTAS
    -- ========================================================================

    -- ------------------------------------------------------------------------
    -- Q1 y Q3: Horas de vuelo y Comparación de Tipos
    -- ------------------------------------------------------------------------
    
    -- Modelo A (DJI-M380): 5 Entregas, 2 Vigilancias
    FOR i IN 1..5 LOOP
        INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
        VALUES (d_modA, 'Entrega', 'Completada', NOW() - interval '5 days', NOW() - interval '5 days' + interval '2 hours');
    END LOOP;
    INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
    VALUES (d_modA, 'Vigilancia', 'Completada', NOW() - interval '2 days', NOW() - interval '2 days' + interval '3 hours');

    -- Modelo B (Skydio-X2): 3 Inspecciones, 4 Entregas
    FOR i IN 1..3 LOOP
        INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
        VALUES (d_modB, 'Inspección', 'Completada', NOW() - interval '10 days', NOW() - interval '10 days' + interval '1.5 hours');
    END LOOP;


    -- ------------------------------------------------------------------------
    -- Q2: Fallas Recurrentes
    -- ------------------------------------------------------------------------
    FOR i IN 1..6 LOOP
        INSERT INTO misiones (dron_id, tipo, estado, inicio, fin, motivo_fallo)
        VALUES (d_fallas, 'Prueba', 'Fallida', NOW() - interval '1 day', NOW() - interval '1 day' + interval '10 minutes', 'Motor explotó');
    END LOOP;


    -- ------------------------------------------------------------------------
    -- Q4: Anomalía de Batería (Misión larga, consumo mínimo)
    -- ------------------------------------------------------------------------
    INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
    VALUES (d_bat, 'Vigilancia', 'Completada', NOW() - interval '1 day', NOW() - interval '1 day' + interval '3 hours')
    RETURNING id INTO m_id;

    INSERT INTO registro_vuelo (mision_id, dron_id, ts, lat, lon, bateria_pct) VALUES 
    (m_id, d_bat, NOW() - interval '1 day', -33.45, -70.66, 100),
    (m_id, d_bat, NOW() - interval '1 day' + interval '3 hours', -33.46, -70.67, 98);


    -- ------------------------------------------------------------------------
    -- Q7: Mantenimiento Masivo (>100 horas de vuelo)
    -- ------------------------------------------------------------------------
    FOR i IN 1..5 LOOP
        INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
        VALUES (d_mant, 'Carga Pesada', 'Completada', NOW() - (i || ' days')::interval, NOW() - (i || ' days')::interval + interval '21 hours');
    END LOOP;


    -- ------------------------------------------------------------------------
    -- Q8: Drones Inactivos
    -- ------------------------------------------------------------------------
    INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
    VALUES (d_old, 'Histórica', 'Completada', NOW() - interval '45 days', NOW() - interval '45 days' + interval '30 minutes');


    -- ------------------------------------------------------------------------
    -- Q9: Análisis Geográfico (POI en -70.66, -33.45)
    -- CORRECCIÓN AQUÍ: No insertamos 'pos', insertamos solo lat/lon
    -- ------------------------------------------------------------------------
    INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
    VALUES (d_poi, 'Espionaje', 'Completada', NOW(), NOW() + interval '10 minutes')
    RETURNING id INTO m_id;

    -- Punto exacto del POI (Postgres generará la columna 'pos' automáticamente)
    INSERT INTO registro_vuelo (mision_id, dron_id, ts, lat, lon, bateria_pct)
    VALUES (m_id, d_poi, NOW(), -33.45000, -70.66000, 90);


    -- ------------------------------------------------------------------------
    -- Q5: Análisis Mensual (Histórico)
    -- ------------------------------------------------------------------------
    FOR i IN 1..6 LOOP
        INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
        VALUES (d_modA, 'Rutina', 'Completada', NOW() - (i || ' months')::interval, NOW() - (i || ' months')::interval + interval '40 minutes');
        
        INSERT INTO misiones (dron_id, tipo, estado, inicio, fin)
        VALUES (d_modB, 'Rutina', 'Completada', NOW() - (i || ' months')::interval, NOW() - (i || ' months')::interval + interval '50 minutes');
    END LOOP;

END $$;

-- ========================================================================
-- 3. REFRESCAR VISTA MATERIALIZADA (Para Q10 y consistencia)
-- ========================================================================
REFRESH MATERIALIZED VIEW drones_db.resumen_misiones_completadas;

SELECT 'Datos de prueba insertados exitosamente.' as resultado;






-- Ejecuta esto en SQL para "ayudar" a la estadística
INSERT INTO misiones (dron_id, tipo, estado, inicio, fin) 
VALUES ((SELECT id FROM drones LIMIT 1), 'GastoAlto', 'Completada', NOW(), NOW() + interval '15 minutes');

-- Insertar consumo de 50% en solo 15 min (muy ineficiente)
INSERT INTO registro_vuelo (mision_id, dron_id, ts, lat, lon, bateria_pct)
VALUES ((SELECT id FROM misiones ORDER BY inicio DESC LIMIT 1), (SELECT id FROM drones LIMIT 1), NOW(), -33.45, -70.66, 100);

INSERT INTO registro_vuelo (mision_id, dron_id, ts, lat, lon, bateria_pct)
VALUES ((SELECT id FROM misiones ORDER BY inicio DESC LIMIT 1), (SELECT id FROM drones LIMIT 1), NOW() + interval '15 minutes', -33.45, -70.66, 50);





---PARA VER A LOS DRONES

UPDATE drones
SET pos = ST_SetSRID(
    ST_MakePoint(
        -70.66 + (random() * 0.04 - 0.02),  -- Longitud aleatoria cerca de Santiago
        -33.45 + (random() * 0.04 - 0.02)   -- Latitud aleatoria cerca de Santiago
    ),
    4326
)::geography
WHERE pos IS NULL;