-- 01_schema.sql
-- Conéctate a la base: dronesdb
-- (En pgAdmin abre Query Tool sobre la BD dronesdb)

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;

-- Esquema lógico
CREATE SCHEMA IF NOT EXISTS drones_db;
SET search_path TO drones_db, public;


-- ================== TABLAS ==================

-- Usuarios
CREATE TABLE IF NOT EXISTS usuarios (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre        text NOT NULL,
  email         citext UNIQUE NOT NULL,
  password_hash text NOT NULL,
  rol           text NOT NULL DEFAULT 'OPERADOR',  -- 'ADMIN' | 'OPERADOR'
  creado_en     timestamptz NOT NULL DEFAULT now()
);

-- Drones
CREATE TABLE IF NOT EXISTS drones (
  id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  modelo          text NOT NULL,
  capacidad_kg    numeric(6,2) NOT NULL CHECK (capacidad_kg >= 0),
  autonomia_min   integer NOT NULL CHECK (autonomia_min >= 0),
  estado          text NOT NULL CHECK (estado IN ('Disponible','En Vuelo','En Mantenimiento')),
  bateria_pct     integer NOT NULL DEFAULT 100 CHECK (bateria_pct BETWEEN 0 AND 100),
  ultima_lat      numeric(9,6),
  ultima_lon      numeric(9,6),
  actualizado_en  timestamptz NOT NULL DEFAULT now()
);

-- Misiones
CREATE TABLE IF NOT EXISTS misiones (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  dron_id       uuid REFERENCES drones(id),
  tipo          text NOT NULL, -- 'Entrega', 'Inspección', 'Vigilancia', etc.
  estado        text NOT NULL CHECK (estado IN ('Pendiente','En Progreso','Completada','Fallida')) DEFAULT 'Pendiente',
  inicio        timestamptz,
  fin           timestamptz,
  ruta_planeada text,       -- JSON serializado (waypoints)
  creado_en     timestamptz NOT NULL DEFAULT now()
);

-- Registro de vuelo (telemetría)
CREATE TABLE IF NOT EXISTS registro_vuelo (
  id          bigserial PRIMARY KEY,
  mision_id   uuid REFERENCES misiones(id),
  dron_id     uuid REFERENCES drones(id),
  ts          timestamptz NOT NULL DEFAULT now(),
  lat         numeric(9,6) NOT NULL,
  lon         numeric(9,6) NOT NULL,
  alt_m       numeric(8,2),
  bateria_pct integer CHECK (bateria_pct BETWEEN 0 AND 100),
  vel_mps     numeric(8,2)
);

-- ================== ÍNDICES ==================
CREATE INDEX IF NOT EXISTS idx_usuarios_email         ON usuarios (email);
CREATE INDEX IF NOT EXISTS idx_drones_estado          ON drones (estado);
CREATE INDEX IF NOT EXISTS idx_drones_modelo          ON drones (modelo);
CREATE INDEX IF NOT EXISTS idx_misiones_estado        ON misiones (estado);
CREATE INDEX IF NOT EXISTS idx_misiones_dron          ON misiones (dron_id);
CREATE INDEX IF NOT EXISTS idx_registro_mision_ts     ON registro_vuelo (mision_id, ts);

-- ================== TRIGGERS ==================

-- Actualiza el dron con la última telemetría
CREATE OR REPLACE FUNCTION fn_sync_dron_desde_telemetria() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE drones
     SET ultima_lat = NEW.lat,
         ultima_lon = NEW.lon,
         bateria_pct = COALESCE(NEW.bateria_pct, bateria_pct),
         actualizado_en = now()
   WHERE id = NEW.dron_id;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_registro_vuelo ON registro_vuelo;
CREATE TRIGGER trg_registro_vuelo
AFTER INSERT ON registro_vuelo
FOR EACH ROW EXECUTE FUNCTION fn_sync_dron_desde_telemetria();

-- Sincroniza estado del dron al cambiar estado de la misión
CREATE OR REPLACE FUNCTION fn_sync_dron_por_mision() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.estado = 'En Progreso' AND NEW.dron_id IS NOT NULL THEN
    UPDATE drones SET estado='En Vuelo' WHERE id = NEW.dron_id;
  ELSIF NEW.estado IN ('Completada','Fallida') AND NEW.dron_id IS NOT NULL THEN
    UPDATE drones SET estado='Disponible' WHERE id = NEW.dron_id;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_mision_estado ON misiones;
CREATE TRIGGER trg_mision_estado
AFTER UPDATE OF estado ON misiones
FOR EACH ROW EXECUTE FUNCTION fn_sync_dron_por_mision();

-- ================== PROCEDIMIENTOS ==================

-- 6) Asignar misión a dron (validaciones + estados)
CREATE OR REPLACE PROCEDURE asignar_mision_a_dron(p_mision uuid, p_dron uuid)
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM misiones WHERE id=p_mision AND dron_id IS NOT NULL) THEN
    RAISE EXCEPTION 'La misión ya está asignada';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM drones WHERE id=p_dron AND estado='Disponible') THEN
    RAISE EXCEPTION 'El dron no está disponible';
  END IF;

  UPDATE misiones
     SET dron_id=p_dron, estado='En Progreso', inicio=COALESCE(inicio, now())
   WHERE id=p_mision;

  UPDATE drones SET estado='En Vuelo' WHERE id=p_dron;
END $$;

-- 7) Mantenimiento por modelo si supera 100 horas
CREATE OR REPLACE PROCEDURE poner_mantenimiento_por_modelo(p_modelo text)
LANGUAGE plpgsql AS $$
BEGIN
  WITH dur AS (
    SELECT d.id,
           SUM(EXTRACT(EPOCH FROM (COALESCE(m.fin,now()) - m.inicio))/3600.0) AS horas
    FROM drones d
    LEFT JOIN misiones m ON m.dron_id = d.id AND m.inicio IS NOT NULL
    WHERE d.modelo = p_modelo
    GROUP BY d.id
  )
  UPDATE drones d
     SET estado='En Mantenimiento'
  FROM dur
  WHERE d.id = dur.id AND dur.horas > 100.0;
END $$;

-- ================== VISTA MATERIALIZADA ==================

DROP MATERIALIZED VIEW IF EXISTS resumen_misiones_completadas;
CREATE MATERIALIZED VIEW resumen_misiones_completadas AS
SELECT tipo,
       COUNT(*) AS total,
       AVG(EXTRACT(EPOCH FROM (COALESCE(fin, NOW()) - inicio))/3600.0) AS horas_promedio
FROM misiones
WHERE estado='Completada'
GROUP BY tipo
WITH NO DATA;

-- Índice único para poder usar REFRESH CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS resumen_misiones_completadas_tipo_idx
  ON resumen_misiones_completadas (tipo);



ALTER DATABASE dronesdb SET search_path TO drones_db, public;
-- (si usas otro rol para la conexión)
-- ALTER ROLE postgres SET search_path TO drones_db, public;

