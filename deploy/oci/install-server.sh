#!/usr/bin/env bash
# Install or update Dooja on Ubuntu 24.04. Run as a sudo user, not root.
# Usage: DOOJA_PUBLIC_HOST=api.example.com bash install-server.sh /tmp/dooja-publish
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as a sudo user, not as root."
  exit 1
fi

PUBLISH_SRC="${1:-/tmp/dooja-publish}"
PUBLIC_HOST="${DOOJA_PUBLIC_HOST:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${PUBLISH_SRC}/Dooja.Web.dll" ]]; then
  echo "Publish folder is missing Dooja.Web.dll: ${PUBLISH_SRC}"
  exit 1
fi
if [[ -z "${PUBLIC_HOST}" ]]; then
  echo "Set DOOJA_PUBLIC_HOST to the public domain or IP before installing."
  exit 1
fi

sudo apt-get update
sudo apt-get install -y nginx curl ca-certificates openssl

if ! command -v dotnet >/dev/null 2>&1; then
  wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
  sudo dpkg -i /tmp/packages-microsoft-prod.deb
  sudo apt-get update
  sudo apt-get install -y aspnetcore-runtime-8.0
fi

if ! id dooja >/dev/null 2>&1; then
  sudo useradd --system --home /var/lib/dooja --shell /usr/sbin/nologin dooja
fi

sudo mkdir -p /opt/dooja /var/lib/dooja /var/backups/dooja /etc/dooja /var/log/dooja

if [[ -f /opt/dooja/Dooja.Web.dll ]]; then
  stamp="$(date +%Y%m%d%H%M%S)"
  sudo tar -C /opt/dooja -czf "/var/backups/dooja/dooja-${stamp}.tar.gz" .
  echo "Backed up the current publish to /var/backups/dooja/dooja-${stamp}.tar.gz"
fi

sudo find /opt/dooja -mindepth 1 -maxdepth 1 -exec rm -rf {} +
sudo cp -a "${PUBLISH_SRC}/." /opt/dooja/
sudo chown -R dooja:dooja /opt/dooja /var/lib/dooja /var/log/dooja
sudo find /opt/dooja -type d -exec chmod 750 {} +
sudo find /opt/dooja -type f -exec chmod 640 {} +
sudo chmod 750 /var/lib/dooja /var/log/dooja

if [[ ! -f /etc/dooja/dooja.env ]]; then
  jwt="$(openssl rand -base64 48 | tr -d '\n')"
  admin="$(openssl rand -base64 18 | tr -d '\n')"
  origin="https://${PUBLIC_HOST}"
  if [[ "${PUBLIC_HOST}" =~ ^[0-9.]+$ ]]; then
    origin="http://${PUBLIC_HOST}"
  fi
  sudo tee /etc/dooja/dooja.env >/dev/null <<EOF
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://127.0.0.1:5080
Database__Provider=Sqlite
ConnectionStrings__Dooja=Data Source=/var/lib/dooja/dooja.db
Seed__Demo=false
Features__Reels=false
AllowedHosts=${PUBLIC_HOST}
Cors__Origins__0=${origin}
Jwt__Key=${jwt}
Admin__Password=${admin}
EOF
  sudo chown root:root /etc/dooja/dooja.env
  sudo chmod 600 /etc/dooja/dooja.env
  echo "Created /etc/dooja/dooja.env. Read Admin__Password over SSH and store it. This script does not print it."
else
  echo "Kept the existing /etc/dooja/dooja.env"
fi

sudo cp "${SCRIPT_DIR}/dooja.service" /etc/systemd/system/dooja.service
sudo systemctl daemon-reload
sudo systemctl enable dooja.service
sudo systemctl restart dooja.service

NGINX_TEMPLATE="${SCRIPT_DIR}/nginx-dooja.conf"
if [[ -f "/etc/letsencrypt/live/${PUBLIC_HOST}/fullchain.pem" ]]; then
  NGINX_TEMPLATE="${SCRIPT_DIR}/nginx-dooja-https.conf"
fi
sudo sed "s/__PUBLIC_HOST__/${PUBLIC_HOST}/g" "${NGINX_TEMPLATE}" | sudo tee /etc/nginx/sites-available/dooja >/dev/null
sudo ln -sfn /etc/nginx/sites-available/dooja /etc/nginx/sites-enabled/dooja
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo "Waiting for /health"
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if curl -fsS http://127.0.0.1:5080/health; then
    echo
    echo "Dooja is listening on 127.0.0.1:5080. Public traffic goes through Nginx only."
    exit 0
  fi
  sleep 2
done

echo "The service did not answer /health. Check: journalctl -u dooja -n 80 --no-pager"
exit 1
