#!/bin/sh
set -eu

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

DB_NAME="${MYSQL_DATABASE:-wordpress}"
DB_USER="${MYSQL_USER:-wpuser}"

ROOT_PW_FILE="/run/secrets/db_root_password"
USER_PW_FILE="/run/secrets/db_password"

if [ ! -f "$ROOT_PW_FILE" ] || [ ! -f "$USER_PW_FILE" ]; then
  echo "Missing required secret files in /run/secrets"
  exit 1
fi

ROOT_PW="$(cat "$ROOT_PW_FILE")"
DB_PW="$(cat "$USER_PW_FILE")"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld "$DATADIR"

if [ ! -d "$DATADIR/.init" ]; then
  echo "Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --datadir="$DATADIR" >/dev/null
  touch "$DATADIR/.init"
fi


echo "Starting temporary MariaDB for provisioning..."
mysqld --user=mysql --datadir="$DATADIR" --socket="$SOCKET" --skip-networking &
pid="$!"

i=0
while ! mariadb-admin --socket="$SOCKET" ping --silent >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -ge 60 ]; then
    echo "MariaDB provisioning timeout"
    kill "$pid" 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

echo "Provisioning database/users..."
if mariadb --socket="$SOCKET" -uroot -e "SELECT 1;" >/dev/null 2>&1; then
  ROOT_CONN="mariadb --socket=$SOCKET -uroot"
else
  ROOT_CONN="mariadb --socket=$SOCKET -uroot -p$ROOT_PW"
fi

$ROOT_CONN <<-SQL
  CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;

  CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PW';
  GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
  FLUSH PRIVILEGES;

  ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PW';
  FLUSH PRIVILEGES;
SQL

echo "Shutting down temporary MariaDB..."
mariadb-admin --socket="$SOCKET" -uroot -p"$ROOT_PW" shutdown >/dev/null 2>&1 || true
wait "$pid" 2>/dev/null || true

echo "Starting MariaDB (TCP 3306)..."
exec mysqld \
  --user=mysql \
  --datadir="$DATADIR" \
  --bind-address=0.0.0.0 \
  --port=3306 \
  --skip-name-resolve
