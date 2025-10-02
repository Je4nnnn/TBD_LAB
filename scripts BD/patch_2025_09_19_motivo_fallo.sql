-- db/patch_2025_09_19_motivo_fallo.sql
SET search_path TO drones_db, public;

ALTER TABLE misiones
ADD COLUMN IF NOT EXISTS motivo_fallo text;
