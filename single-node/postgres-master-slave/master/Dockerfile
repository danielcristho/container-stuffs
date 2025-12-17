FROM postgres:16-alpine

# Add initialization SQL
COPY init.sql /docker-entrypoint-initdb.d/init.sql

COPY postgresql.conf /etc/postgresql/postgresql.conf

COPY pg_hba.conf /etc/postgresql/pg_hba.conf

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
