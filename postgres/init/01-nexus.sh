#!/bin/sh
set -eu
# This entrypoint runs only when the PostgreSQL data directory is empty.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
SELECT format('CREATE DATABASE nexus OWNER %I', current_user)
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'nexus')\gexec
SQL
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname nexus <<'SQL'
CREATE EXTENSION IF NOT EXISTS pg_trgm;
SQL
