#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] || python3 scripts/prepare.py
sudo docker compose config --quiet
sudo docker compose pull
sudo docker compose up -d
echo 'Nexus can take several minutes to start. Run: sudo bash scripts/verify.sh'
