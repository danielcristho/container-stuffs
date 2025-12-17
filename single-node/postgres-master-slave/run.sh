#!/bin/bash
set -e

source .env

MASTER_HOST=10.0.2.10
SLAVE_HOST=10.0.2.11

echo "Cleanup..."
docker compose down -v
rm -rf master/data/*
rm -rf slave/data/*

echo "Starting containers..."
docker compose up --build -d

echo "Create archive dir on master..."
docker exec -u postgres postgres_master mkdir -p /var/lib/postgresql/data/archive
docker exec -u postgres postgres_master chown -R postgres:postgres /var/lib/postgresql/data/archive

echo "Waiting master ready..."
until docker exec postgres_master pg_isready -U "$POSTGRES_USER" -p 5432 >/dev/null 2>&1; do
    sleep 2
done

echo "Creating replication user if not exists..."
docker exec postgres_master psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${REPLICATION_USER}') THEN
        CREATE ROLE ${REPLICATION_USER} WITH REPLICATION LOGIN PASSWORD '${REPLICATION_PASSWORD}';
    END IF;
END
\$\$;"

echo "Preparing slave directory..."
docker exec -u root postgres_slave bash -c "
    rm -rf /var/lib/postgresql/data/*
    mkdir -p /var/lib/postgresql/data
    chown -R postgres:postgres /var/lib/postgresql/data
    chmod 700 /var/lib/postgresql/data
"

docker exec -u postgres postgres_slave bash -c "
    PGPASSWORD=${REPLICATION_PASSWORD} pg_basebackup \
        -h ${MASTER_HOST} -U ${REPLICATION_USER} \
        -D /var/lib/postgresql/data -Fp -Xs -P -R
"

echo "Fixing ownership after basebackup..."
docker exec -u root postgres_slave bash -c "
    chown -R postgres:postgres /var/lib/postgresql/data
    chmod 700 /var/lib/postgresql/data
"

echo "Starting slave database..."
docker exec -u postgres postgres_slave pg_ctl -D /var/lib/postgresql/data start
sleep 5

echo "Replication status:"
docker exec postgres_master psql -U "$POSTGRES_USER" -c "SELECT client_addr, state FROM pg_stat_replication;"
docker exec -u postgres postgres_slave psql -d postgres -c \
"SELECT status, receive_start_lsn, received_lsn, latest_end_lsn FROM pg_stat_wal_receiver;"