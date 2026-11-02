#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dc() { docker compose "$@"; }
bind_ip=$(sed -n 's/^BIND_IP=//p' .env)
pgadmin_port=$(sed -n 's/^PGADMIN_PORT=//p' .env)
nexus_port=$(sed -n 's/^NEXUS_PORT=//p' .env)
dc ps
dc exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT version(), current_database(), current_user;"'
dc exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d nexus -c "SELECT extname FROM pg_extension WHERE extname = '\''pg_trgm'\'';"'
curl --fail --silent --show-error "http://${bind_ip:-127.0.0.1}:${pgadmin_port:-5050}/misc/ping"
echo
curl --fail --silent --show-error "http://${bind_ip:-127.0.0.1}:${nexus_port:-8081}/service/rest/v1/status"
echo
# A healthy Nexus HTTP endpoint alone does not prove PostgreSQL is used.
dc exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d nexus -c "SELECT count(*) AS nexus_tables FROM information_schema.tables WHERE table_schema NOT IN ('\''pg_catalog'\'', '\''information_schema'\''); SELECT datname, usename, application_name, state FROM pg_stat_activity WHERE datname = '\''nexus'\'';"'
table_count=$(dc exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -At -U "$POSTGRES_USER" -d nexus -c "SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('\''pg_catalog'\'', '\''information_schema'\'');"')
[[ "$table_count" -gt 0 ]] || { echo 'FAIL: Nexus metadata tables were not created.' >&2; exit 1; }
echo 'PASS: PostgreSQL, pgAdmin, Nexus HTTP and Nexus metadata tables.'
