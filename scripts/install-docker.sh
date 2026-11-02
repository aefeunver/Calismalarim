#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo 'Run: sudo bash scripts/install-docker.sh' >&2
  exit 1
fi
if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
  systemctl enable --now docker
  docker version --format '{{.Server.Version}}'
  exit 0
fi
. /etc/os-release
case "${ID:-}" in
  pardus|debian) ;;
  *) echo 'This script supports Pardus and Debian only.' >&2; exit 1 ;;
esac
debian_major=$(cut -d. -f1 /etc/debian_version)
case "$debian_major" in
  13) codename=trixie ;;
  12) codename=bookworm ;;
  *) echo "Confirm the Debian base manually: $(cat /etc/debian_version)" >&2; exit 1 ;;
esac
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $codename
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
docker version --format '{{.Server.Version}}'
docker compose version
