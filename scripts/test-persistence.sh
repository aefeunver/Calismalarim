#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' <<'SQL'
CREATE TABLE IF NOT EXISTS odev_kalicilik (
  id integer PRIMARY KEY,
  aciklama text NOT NULL,
  olusturulma timestamptz DEFAULT now()
);
INSERT INTO odev_kalicilik (id, aciklama)
VALUES (1, '20261102-pardus-docker-odevi')
ON CONFLICT (id) DO NOTHING;
SELECT * FROM odev_kalicilik;
SQL
echo 'Container IDs BEFORE recreation:'
docker compose ps -q
docker compose stop
docker compose up -d --force-recreate
echo 'Container IDs AFTER recreation:'
docker compose ps -q
host=$(sed -n 's/^BIND_IP=//p' .env)
for attempt in $(seq 1 40); do
  if curl --fail --silent "http://$host:8081/service/rest/v1/status" >/dev/null && curl --fail --silent "http://$host:5050/misc/ping" >/dev/null; then
    break
  fi
  sleep 3
done
docker compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT * FROM odev_kalicilik;"'
python3 - <<'PY'
from pathlib import Path
import base64
import urllib.request
env = dict(line.split('=', 1) for line in Path('.env').read_text().splitlines() if line and not line.startswith('#'))
auth = base64.b64encode((env['POSTGRES_USER'] + ':' + env['POSTGRES_PASSWORD']).encode()).decode()
url = 'http://' + env['BIND_IP'] + ':8081/repository/odev-raw/odev/merhaba.txt'
req = urllib.request.Request(url, headers={'Authorization': 'Basic ' + auth})
with urllib.request.urlopen(req, timeout=30) as response:
    payload = response.read().decode()
assert payload == 'Pardus + Docker + PostgreSQL + pgAdmin + Nexus odev testi.\n'
print('PASS: Existing Nexus repository, user credentials and artifact survived container recreation.')
PY
bash scripts/verify.sh
