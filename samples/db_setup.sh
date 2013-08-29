#!/bin/sh

PORT=5432
HOST="localhost"

PGSQL_DIR="./data"
PGSQL_LOG="./data/LOG"

function r_echo {
	echo "\033[31m$@\033[37m"
}

function r_exec {
	r_echo "$@"
	$@
}

function g_echo {
	echo "\033[32m$@\033[37m"
}

function g_exec {
	g_echo "$@"
	$@
}

function stop_server {
    	r_exec pg_ctl stop -D $PGSQL_DIR -l $PGSQL_LOG
}

function start_server_if_not_running {
	g_exec pg_ctl status -D $PGSQL_DIR | grep 'no server running' 2> /dev/null > /dev/null
	if [ $? = 0 ]; then # server is not running
		g_echo "pg_ctl -o "-F -p $PORT"  -D $PGSQL_DIR -l $PGSQL_LOG start"
		pg_ctl -o "-F -p $PORT" -D $PGSQL_DIR -l $PGSQL_LOG start
	fi
}

case $1 in
	"list")
		g_exec psql -p $PORT -h $HOST -l;;
	"init")
		g_exec initdb $PGSQL_DIR
		start_server_if_not_running;;
    "create")
		if [ $# -gt 2 ]; then
			g_exec createdb -p $PORT -h $HOST $2
            g_exec psql -h $HOST -p $PORT -d $2 -f $3
		else
            r_exec "usage: ./db_setup.sh create <db_name> <schema.sql>"
        fi;;
	"start")
		start_server_if_not_running;;
	"stop")
		stop_server;;
	"status")
		pg_ctl status -D $PGSQL_DIR;;
	"drop")
        dropdb -p $PORT -h $HOST $2;;
    "exec")
        shift
		g_exec psql -p $PORT -h $HOST $@;;
	"clean")
		g_exec stop_server
		r_exec rm -rf $PGSQL_LOG
		r_exec rm -rf $PGSQL_DIR;;
	*)
		r_echo "fatal error: invalid option";;

esac
