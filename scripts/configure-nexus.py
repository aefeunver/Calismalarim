#!/usr/bin/env python3
"""Configure this local homework Nexus. EULA acceptance requires an explicit flag."""
import argparse
import base64
import json
from pathlib import Path
import secrets
import subprocess
import urllib.error
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument('--accept-eula', action='store_true', help='Accept the Sonatype CE EULA only after reviewing it.')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
env = dict(line.split('=', 1) for line in (root / '.env').read_text().splitlines() if line and not line.startswith('#'))
base = f"http://{env.get('BIND_IP', '127.0.0.1')}:{env.get('NEXUS_PORT', '8081')}"
state_file = root / 'private' / 'nexus-admin.password'
if state_file.exists():
    admin_password = state_file.read_text().strip()
else:
    admin_password = subprocess.check_output(['docker', 'exec', 'odev-nexus', 'cat', '/nexus-data/admin.password'], text=True).strip()

def request(method, path, data=None, raw=False, account=None):
    user, password = account or ('admin', admin_password)
    headers = {'Authorization': 'Basic ' + base64.b64encode(f'{user}:{password}'.encode()).decode()}
    if data is not None:
        headers['Content-Type'] = 'text/plain' if raw else 'application/json'
        data = data.encode() if raw else json.dumps(data).encode()
    req = urllib.request.Request(base + path, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=30) as response:
        return response.status, response.read()

_, payload = request('GET', '/service/rest/v1/system/eula')
eula = json.loads(payload)
if not eula.get('accepted'):
    if not args.accept_eula:
        raise SystemExit('Review https://links.sonatype.com/products/nxrm/ce-eula and explicitly use --accept-eula if you agree.')
    request('POST', '/service/rest/v1/system/eula', {'accepted': True, 'disclaimer': eula.get('disclaimer', '')})
    print('EULA acceptance submitted with explicit operator consent.')

if not state_file.exists():
    new_password = secrets.token_hex(18)
    request('PUT', '/service/rest/v1/security/users/admin/change-password', new_password, raw=True)
    state_file.parent.mkdir(mode=0o700, exist_ok=True)
    state_file.write_text(new_password + '\n')
    state_file.chmod(0o600)
    admin_password = new_password
    print('Initial admin credential rotated; saved locally, not printed.')

_, payload = request('GET', '/service/rest/v1/security/users')
users = json.loads(payload)
username = env['POSTGRES_USER']
if not any(user['userId'] == username for user in users):
    request('POST', '/service/rest/v1/security/users', {
        'userId': username, 'firstName': 'Adem', 'lastName': 'Lab',
        'emailAddress': env['PGADMIN_DEFAULT_EMAIL'], 'password': env['POSTGRES_PASSWORD'],
        'status': 'active', 'roles': ['nx-admin'],
    })
    print('Created local homework Nexus user matching PostgreSQL credentials.')

_, payload = request('GET', '/service/rest/v1/repositories')
if not any(repo['name'] == 'odev-raw' for repo in json.loads(payload)):
    request('POST', '/service/rest/v1/repositories/raw/hosted', {
        'name': 'odev-raw', 'online': True,
        'storage': {'blobStoreName': 'default', 'strictContentTypeValidation': False, 'writePolicy': 'ALLOW'},
    })

artifact = 'Pardus + Docker + PostgreSQL + pgAdmin + Nexus odev testi.\n'
request('PUT', '/repository/odev-raw/odev/merhaba.txt', artifact, raw=True,
        account=(username, env['POSTGRES_PASSWORD']))
_, downloaded = request('GET', '/repository/odev-raw/odev/merhaba.txt', account=(username, env['POSTGRES_PASSWORD']))
assert downloaded.decode() == artifact, 'Artifact round trip failed.'
print('PASS: Nexus hosted repository, upload, download, and matching credentials.')

access = root / 'access.txt'
access.write_text(
    'YEREL GIRIS BILGILERI - GITHUBA YUKLEMEYIN\n\n'
    f"PostgreSQL adresi: {env.get('BIND_IP', '127.0.0.1')}:5432\n"
    f"PostgreSQL kullanici: {username}\nPostgreSQL parola: {env['POSTGRES_PASSWORD']}\n"
    f"Odev veritabani: {env['POSTGRES_DB']}\nNexus metadata veritabani: nexus\n\n"
    f"pgAdmin: http://{env.get('BIND_IP', '127.0.0.1')}:5050\n"
    f"pgAdmin e-posta: {env['PGADMIN_DEFAULT_EMAIL']}\npgAdmin parola: {env['PGADMIN_DEFAULT_PASSWORD']}\n"
    'pgAdmin icinde PostgreSQL sunucu adresi: postgres; port: 5432\n\n'
    f'Nexus: {base}\nNexus kullanici: {username}\nNexus parola: {env["POSTGRES_PASSWORD"]}\n'
    f'Nexus yedek yonetici: admin\nNexus admin parola: {admin_password}\n'
    f'Ornek artifact: {base}/repository/odev-raw/odev/merhaba.txt\n',
    encoding='utf-8',
)
access.chmod(0o600)
print('Saved final credentials only in ignored local access.txt.')
