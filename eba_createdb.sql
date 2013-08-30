-- qu :
--- index, clés primaires et contraintes ?

-- E
CREATE TABLE users (
       userid bigserial primary key,
       pwd text,
       firstname text NOT NULL,
       lastname text NOT NULL,
       pic text
);

-- A
CREATE TABLE emails (
       email text primary key,
       userid bigint NOT NULL references users(userid)
);

CREATE TABLE activation (
       activationkey text primary key,
       userid bigint NOT NULL references users(userid),
       creationdate timestamp NOT NULL default now()
);

-- A
CREATE TABLE contacts (
       userid bigint NOT NULL references users(userid),
       contactid bigint NOT NULL references users(userid),
       primary key (userid, contactid) --- ???VVV Why?
);

-- A
CREATE TABLE preregister (
       email text primary key
);

CREATE TABLE groups (
       groupid bigserial primary key,
       name text NOT NULL,
       description text
);

CREATE TABLE user_groups (
       userid bigint NOT NULL references users(userid),
       groupid bigint NOT NULL references groups(groupid)
);

CREATE TABLE egroups (
       groupid bigserial primary key,
       name text NOT NULL,
       description text
);

CREATE TABLE email_egroups (
       email text NOT NULL,
       groupid bigint NOT NULL references egroups(groupid)
);
