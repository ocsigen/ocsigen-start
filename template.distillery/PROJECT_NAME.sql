-- The tables of the %%%PROJECT_NAME%%% application. The tables of Ocsigen
-- Start are in ocsigen_start.sql.
--
-- `make db-update` applies ocsigen_start.sql, then this file. Keep this
-- file replayable, so that the same command creates the schema of a new
-- database and brings an existing one up to date: guard every statement
-- (CREATE TABLE IF NOT EXISTS, ALTER TABLE ... ADD COLUMN IF NOT EXISTS,
-- CREATE INDEX IF NOT EXISTS, CREATE OR REPLACE FUNCTION, DROP TRIGGER IF
-- EXISTS before CREATE TRIGGER, a DO block for a data migration) and append
-- the changes at the end instead of rewriting earlier statements, since
-- existing databases have already run them. The same goes for the columns
-- you add to the tables of Ocsigen Start, for example:
--
--   ALTER TABLE ocsigen_start.users ADD COLUMN IF NOT EXISTS birthday date;

\set ON_ERROR_STOP true
SET client_min_messages TO WARNING;

BEGIN;

-- CREATE SCHEMA IF NOT EXISTS %%%PROJECT_NAME%%%;
--
-- CREATE TABLE IF NOT EXISTS %%%PROJECT_NAME%%%.items (
--        itemid bigserial primary key,
--        userid bigint NOT NULL references ocsigen_start.users(userid),
--        name text NOT NULL
-- );

COMMIT;
