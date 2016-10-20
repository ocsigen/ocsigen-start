-- README:
-- Do not remove the field with a `-- DEFAULT` suffix.
-- That's the default tables/fields needed by Ocsigen-start

CREATE DATABASE ocsipersist;

CREATE EXTENSION citext; --DEFAULT
-- You may remove the above line if you use the type TEXT for emails instead of CITEXT

CREATE SCHEMA ocsigen_start
  CREATE TABLE users ( -- DEFAULT
         userid bigserial primary key, -- DEFAULT
         firstname text NOT NULL,
         lastname text NOT NULL,
         main_email citext NOT NULL,
         password text,
         avatar text
  )

  CREATE TABLE emails ( -- DEFAULT
         email citext primary key, -- DEFAULT
         userid bigint NOT NULL references users(userid), -- DEFAULT
         validated boolean NOT NULL DEFAULT(false)
  )

  CREATE TABLE activation ( -- DEFAULT
         activationkey text primary key, -- DEFAULT
         userid bigint NOT NULL references users(userid), -- DEFAULT
         email citext NOT NULL,
         autoconnect boolean NOT NULL,
         validity bigint NOT NULL,
         action text NOT NULL,
         data text NOT NULL,
         creationdate timestamptz NOT NULL default now()
  )

  CREATE TABLE groups ( -- DEFAULT
         groupid bigserial primary key, -- DEFAULT
         name text NOT NULL, -- DEFAULT
         description text -- DEFAULT
  )

  CREATE TABLE user_groups ( -- DEFAULT
         userid bigint NOT NULL references users(userid), -- DEFAULT
         groupid bigint NOT NULL references groups(groupid) -- DEFAULT
  )

  CREATE TABLE preregister (
         email citext NOT NULL
  );
