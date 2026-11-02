#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
stamp=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$stamp"
docker compose exec -T postgres sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "backups/$stamp/odev.dump"
# Stop Nexus so metadata and blobs belong to the same consistent backup window.
docker compose stop nexus pgadmin
trap 'docker compose start nexus pgadmin >/dev/null' EXIT
docker compose exec -T postgres sh -c 'pg_dump -U "$POSTGRES_USER" -d nexus -Fc' > "backups/$stamp/nexus.dump"
docker run --rm --volumes-from odev-nexus:ro -v "$PWD/backups/$stamp:/backup" alpine:3.22 tar czf /backup/nexus-data.tgz -C /nexus-data .
docker run --rm --volumes-from odev-pgadmin:ro -v "$PWD/backups/$stamp:/backup" alpine:3.22 tar czf /backup/pgadmin-data.tgz -C /var/lib/pgadmin .
echo "Backup saved under backups/$stamp (not tracked by Git)."
