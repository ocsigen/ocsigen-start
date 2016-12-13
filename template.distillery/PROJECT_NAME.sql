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
  )
  -- Table for OAuth2.0 server. An Eliom application can be an OAuth2.0 server.
  -- Its client can be an Eliom application, but not always.

  ---- Table to represent and register clients
  CREATE TABLE oauth2_server_client (
         id bigserial primary key,
         application_name text not NULL,
         description text not NULL,
         redirect_uri text not NULL,
         client_id text not NULL,
         client_secret text not NULL
  )

  -- Table for OAuth2.0 client. An Eliom application can be a OAuth2.0 client of a
  -- OAuth2.0 server which can be also an Eliom application, but not always.
  CREATE TABLE oauth2_client_credentials (
         -- Is it very useful ? Remove it implies an application can be a OAuth
         -- client of a OAuth server only one time. For the moment, algorithms works
         -- with the server_id which are the name and so id is useless.
         id bigserial primary key,
         server_id text not NULL, -- to remember which OAuth2.0 server is. The server name can be used.
         server_authorization_url text not NULL,
         server_token_url text not NULL,
         server_data_url text not NULL,
         client_id text not NULL,
         client_secret text not NULL
  );
