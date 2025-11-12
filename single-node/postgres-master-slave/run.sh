#!/bin/bash
set -e

if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found!!"
    exit 1
fi

MASTER_HOST=10.0.2.10
SLAVE_HOST=10.0.2.11


echo "Cleanup old containers and volumes..."
docker compose down -v
rm -rf ./master/data/*
rm -rf ./slave/data/*

echo "Starting POSTGRESQL containers..."
docker compose up --build -d

echo "Waiting for Master ($MASTER_HOST) container to be ready..."
until docker exec postgres_master pg_isready -U "$POSTGRES_USER" >/dev/null 2>&1; do
    sleep 2
done
echo "Master is ready"

echo "Ensuring replication user exists..."
docker exec postgres_master psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c \
"DO \$\$BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$REPLICATION_USER') THEN
        CREATE ROLE $REPLICATION_USER WITH REPLICATION LOGIN PASSWORD '$REPLICATION_PASSWORD';
    END IF;
    END\$\$;"

echo "Ensuring replication user exists..."
docker exec postgres_master psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c \
"DO \$\$BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$REPLICATION_USER') THEN
        CREATE ROLE $REPLICATION_USER WITH REPLICATION LOGIN PASSWORD '$REPLICATION_PASSWORD';
    END IF;
END\$\$;"

echo "Preparing replica data directory..."
docker exec postgres_slave bash -c "
    pg_ctl -D /var/lib/postgresql/data stop >/dev/null 2>&1 || true
    rm -rf /var/lib/postgresql/data/*
    PGPASSWORD=$REPLICATION_PASSWORD pg_basebackup -h $MASTER_HOST -U $REPLICATION_USER \
    -D /var/lib/postgresql/data -Fp -Xs -P -R
"

echo "Restarting slave..."
docker exec postgres_slave bash -c "pg_ctl -D /var/lib/postgresql/data start"


echo "Checking replication status..."
sleep 5
docker exec postgres_master psql -U "$POSTGRES_USER" -c "SELECT client_addr, state FROM pg_stat_replication;"
docker exec postgres_slave psql -U "$POSTGRES_USER" -c "SELECT status FROM pg_stat_wal_receiver;"

echo ""
echo "PostgreSQL streaming replication setup complete!"
echo "Master: $MASTER_HOST (port 5432)"
echo "Replica: $SLAVE_HOST (port 5433)"
echo ""
echo "Try inserting data on the master and query it on the replica to verify replication."
