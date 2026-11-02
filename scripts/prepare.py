#!/usr/bin/env python3
"""Generate local credentials and pgAdmin server registration; never overwrite .env."""
import json
import os
from pathlib import Path
import secrets

ROOT = Path(__file__).resolve().parents[1]
env_path = ROOT / '.env'
if env_path.exists():
    raise SystemExit('.env already exists; preserving existing credentials.')
db_password = secrets.token_hex(18)
pgadmin_password = secrets.token_hex(18)
env = {
    'POSTGRES_USER': 'adem',
    'POSTGRES_PASSWORD': db_password,
    'POSTGRES_DB': 'odev',
    'PGADMIN_DEFAULT_EMAIL': 'adem@example.com',
    'PGADMIN_DEFAULT_PASSWORD': pgadmin_password,
    'BIND_IP': '127.0.0.1',
    'POSTGRES_PORT': '5432',
    'PGADMIN_PORT': '5050',
    'NEXUS_PORT': '8081',
    'NEXUS_IMAGE': 'sonatype/nexus3:3.77.2-java17-alpine',
    'PGADMIN_IMAGE': 'dpage/pgadmin4:9.18',
}
old_umask = os.umask(0o077)
try:
    env_path.write_text(''.join(f'{key}={value}\n' for key, value in env.items()), encoding='utf-8')
    (ROOT / 'access.txt').write_text(
        'LOCAL ACCESS INFORMATION - DO NOT UPLOAD\n'
        'PostgreSQL user: adem\n'
        f'PostgreSQL password: {db_password}\n'
        'PostgreSQL database: odev\n'
        'Nexus metadata database: nexus\n'
        'pgAdmin URL: http://127.0.0.1:5050\n'
        'pgAdmin email: adem@example.com\n'
        f'pgAdmin password: {pgadmin_password}\n'
        'Nexus URL: http://127.0.0.1:8081\n'
        'Nexus initial admin password: sudo docker compose exec -T nexus cat /nexus-data/admin.password\n',
        encoding='utf-8',
    )
finally:
    os.umask(old_umask)
(ROOT / 'pgadmin').mkdir(exist_ok=True)
servers = {
    'Servers': {
        '1': {'Name': 'Pardus PostgreSQL 18.6', 'Group': 'Odev', 'Host': 'postgres',
              'Port': 5432, 'MaintenanceDB': 'odev', 'Username': 'adem', 'SSLMode': 'prefer'},
        '2': {'Name': 'Nexus metadata', 'Group': 'Odev', 'Host': 'postgres',
              'Port': 5432, 'MaintenanceDB': 'nexus', 'Username': 'adem', 'SSLMode': 'prefer'},
    }
}
(ROOT / 'pgadmin' / 'servers.json').write_text(json.dumps(servers, indent=2) + '\n', encoding='utf-8')
print('Created .env, access.txt, and pgadmin/servers.json. Credentials were not printed.')
