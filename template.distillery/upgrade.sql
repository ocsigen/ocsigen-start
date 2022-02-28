CREATE SCHEMA ocsigen_start;

ALTER TABLE activation   SET SCHEMA ocsigen_start;
ALTER TABLE emails       SET SCHEMA ocsigen_start;
ALTER TABLE groups       SET SCHEMA ocsigen_start;
ALTER TABLE preregister  SET SCHEMA ocsigen_start;
ALTER TABLE user_groups  SET SCHEMA ocsigen_start;
ALTER TABLE users        SET SCHEMA ocsigen_start;

ALTER TABLE ocsigen_start.activation ADD COLUMN IF NOT EXISTS expiry timestamp;

DO $$ BEGIN
    DELETE FROM ocsigen_start.groups AS g
        WHERE g.groupid IN (
            SELECT g1.groupid
                FROM ocsigen_start.groups AS g1
                WHERE EXISTS (
                    SELECT *
                        FROM ocsigen_start.groups AS g2
                        WHERE g1.name = g2.name
                        AND g1.groupid > g2.groupid
                )
        );
    IF NOT EXISTS (
        SELECT *
            FROM information_schema.constraint_column_usage AS c
            WHERE c.table_name = 'groups'
            AND c.constraint_name = 'groups_name_key'
            AND c.constraint_schema = 'ocsigen_start'
    ) THEN
        ALTER TABLE ocsigen_start.groups
            ADD CONSTRAINT groups_name_key UNIQUE (name);
    END IF;
END; $$;
