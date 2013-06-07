-- qu :
--- index, clés primaires et contraintes ?

-- E
CREATE TABLE users (
       userid bigserial primary key,
       pwd text,
       firstname text NOT NULL,
       lastname text NOT NULL,
       rights smallint NOT NULL, -- no default value because of macaque
       pic text
);

-- A
CREATE TABLE emails (
       email text primary key,
       userid bigint NOT NULL references users(userid)
);

CREATE TABLE activation (
       activationkey text primary key,
       email text NOT NULL references emails(email),
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

CREATE TABLE global_informations (
       state smallint NOT NULL -- 0 = WIP, 1 = on production
);
