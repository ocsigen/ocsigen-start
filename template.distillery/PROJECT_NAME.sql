-- README:
-- Do not remove the field with a `-- DEFAULT` suffix.
-- That's the default tables/fields needed by Ocsigen-start

CREATE DATABASE ocsipersist_%%%PROJECT_NAME%%%;

CREATE EXTENSION citext; --DEFAULT
-- You may remove the above line if you use the type TEXT for emails instead of CITEXT

CREATE SCHEMA ocsigen_start

  -- Note that `main_email` is not an `emails` foreign key to prevent a circular
  -- dependency. Triggers on table `emails` defined below make sure this column
  -- stays in sync
  CREATE TABLE users ( -- DEFAULT
         userid bigserial primary key, -- DEFAULT
         firstname text NOT NULL,
         lastname text NOT NULL,
         main_email citext,
         password text,
         avatar text,
         language text
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
         validity bigint NOT NULL default 1,
         action text NOT NULL,
         data text NOT NULL,
         creationdate timestamp NOT NULL default (now() at time zone 'utc'),
         expiry timestamp
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

  CREATE TABLE phones (
       number citext primary key,
       userid bigint NOT NULL references users(userid)
  );


CREATE OR REPLACE FUNCTION can_delete_email ()
  RETURNS TRIGGER AS $$
  BEGIN
    IF (EXISTS (SELECT 1
                FROM ocsigen_start.emails, ocsigen_start.users
                WHERE emails.userid = old.userid
                  AND users.userid = old.userid
                  AND emails.email <> old.email
                  AND users.main_email = emails.email
                  AND validated))
    THEN
      RETURN old;
    ELSE
      RETURN NULL;
    END IF;
  END;
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION can_delete_phone ()
  RETURNS TRIGGER AS $$
  BEGIN
    IF (EXISTS (SELECT 1
                FROM ocsigen_start.phones
                WHERE userid = old.userid AND number <> old.number) OR
        EXISTS (SELECT 1
                FROM ocsigen_start.emails
                WHERE userid = old.userid
                  AND validated))
    THEN
      RETURN old;
    ELSE
      RETURN NULL;
    END IF;
  END;
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_main_email ()
  RETURNS TRIGGER AS $$
  BEGIN
    IF (EXISTS (SELECT 1
                FROM  ocsigen_start.users
                WHERE users.userid = NEW.userid
                  AND (users.main_email IS NULL OR
                       users.main_email NOT SIMILAR TO '%@%')))
    THEN
      UPDATE users
         SET main_email = NEW.email WHERE users.userid = NEW.userid;
    END IF;
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;

  CREATE OR REPLACE
    FUNCTION trigger_exists (t_name text)
    RETURNS boolean
    STABLE AS $$
      SELECT EXISTS
        (SELECT 1 FROM pg_trigger
                  WHERE NOT tgisinternal
                  AND tgname = t_name)
    $$ LANGUAGE SQL;


DO $$
  BEGIN
    IF NOT trigger_exists('can_delete_phone') THEN
      CREATE TRIGGER can_delete_phone
      BEFORE DELETE on ocsigen_start.phones
      FOR EACH ROW
      EXECUTE PROCEDURE can_delete_phone();
    END IF;
    IF NOT trigger_exists('can_delete_email') THEN
      CREATE TRIGGER can_delete_email
      BEFORE DELETE on ocsigen_start.emails
      FOR EACH ROW
      EXECUTE PROCEDURE can_delete_email();
    END IF;
    IF NOT trigger_exists('set_main_email') THEN
      CREATE TRIGGER set_main_email
      AFTER INSERT on ocsigen_start.emails
      FOR EACH ROW
      EXECUTE PROCEDURE set_main_email();
    END IF;
  END;
$$;
