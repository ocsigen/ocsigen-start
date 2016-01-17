-- README:
-- Do not remove the field with a `-- DEFAULT` suffix.
-- That's the default tables/fields needed by Eliom-base-app

CREATE TABLE users ( -- DEFAULT
       userid bigserial primary key, -- DEFAULT
       firstname text NOT NULL,
       lastname text NOT NULL,
       password text,
       avatar text
);

-- Eliom-base-app permits one user to have multiple e-mails.
-- These multiple e-mails have three different states:
-- * non_activated: the user did not click on the
--   activation link sent by the application yet.
-- * activated: the user clicked on the link but had already
--   a primary e-mail and did not decide to set the newly activated
--   one as primary.
-- * primary: it's either the first activated e-mail of the user,
--   or one that was manually set as primary by the user.

-- With these three states, three features are provided:
-- * login: the user can only login using its primary email,
-- * password_recovery: a recovery link can be sent to any of the user's
--   activated emails,
-- * non_activated -> activated <-> primary transitions:
--   * non_activated -> activated: click on the activation link sent
--     by the application,
--   * activated <-> primary: user interface provided by the application.

-- From that model, the following enum seems adapted to implement the state.
--
-- CREATE TYPE email_state AS ENUM ('non_activated', 'activated', 'primary');
--
-- However macaque does not seem to support enum's yet.
-- We implement the state with two booleans (is_primary, is_activated),
-- and delegate the task of ensuring the erroneous state
-- (is_primary, not is_activated) does not appear, to the application.

CREATE TABLE emails ( -- DEFAULT
       email text,
       userid bigint NOT NULL references users(userid), -- DEFAULT
       is_primary boolean NOT NULL,
       is_activated boolean NOT NULL
);

-- To identify which 'other' erroneous state checking could be implemented
-- by the database:
-- * if we put 'email' as primary key, one
--   could register (without validating) any email address
--   and make it difficult for the actual owner of the email address
--   to use it:
--  'email' must ** not be ** a primary key.
-- * if we consider the use case of a parent,
--   setting the same recovery address to all of its children account,
--   the same activated email could be shared among multiple users:
--   ** no constraint ** on activated emails.

-- The remainings are thus:
-- * primary emails must be unique, so that we can identify
--   which user logged-in. This constraint is however not
--   strong enough to add the constraint
--   'email text NOT NULL references emails(email)'
--   in the activation table below.
--   http://stackoverflow.com/questions/11966420/what-is-causing-error-there-is-no-unique-constraint-matching-given-keys-for-ref
--   This check is left to the application.
CREATE UNIQUE INDEX email_unique ON emails (email) WHERE is_primary;
-- * users must have at most one primary email, not to handle
--   unecessary situations in the application.
CREATE UNIQUE INDEX user_unique ON emails (userid) WHERE is_primary;
-- * users don't have dupicated e-mails.
CREATE UNIQUE INDEX users_dont_have_duplicated_emails ON emails (email, userid);


CREATE TABLE activation ( -- DEFAULT
       activationkey text primary key, -- DEFAULT
       email text NOT NULL, -- DEFAULT
       userid bigint NOT NULL references users(userid), -- DEFAULT
       creationdate timestamptz NOT NULL default now()
);

CREATE TABLE groups ( -- DEFAULT
       groupid bigserial primary key, -- DEFAULT
       name text NOT NULL, -- DEFAULT
       description text -- DEFAULT
);

CREATE TABLE user_groups ( -- DEFAULT
       userid bigint NOT NULL references users(userid), -- DEFAULT
       groupid bigint NOT NULL references groups(groupid) -- DEFAULT
);

CREATE TABLE preregister (
       email text NOT NULL
);
