#!/bin/sh

PORT=5432
HOST="localhost"
DB="eba"

echo $1
echo $@

QUERY_RES=$(
cat << EOF

select users.rights
    from emails
    join users
    on emails.userid = users.userid;

EOF)

QUERY=$(
cat << EOF

update users
    from emails
    where emails.userid = users.userid;

EOF)

echo $QUERY_RES | psql -p $PORT -h $HOST $DB
echo $QUERY     | psql -p $PORT -h $HOST $DB
echo $QUERY_RES | psql -p $PORT -h $HOST $DB
