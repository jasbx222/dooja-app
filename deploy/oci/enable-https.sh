#!/usr/bin/env bash
# Issue a Let's Encrypt certificate and switch Nginx to HTTPS.
# Requires a DNS A record already pointing at this VM, and ports 80 and 443 open.
# Usage: DOOJA_PUBLIC_HOST=api.example.com DOOJA_CERT_EMAIL=you@example.com bash enable-https.sh
set -euo pipefail

PUBLIC_HOST="${DOOJA_PUBLIC_HOST:-}"
EMAIL="${DOOJA_CERT_EMAIL:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${PUBLIC_HOST}" || -z "${EMAIL}" ]]; then
  echo "Set DOOJA_PUBLIC_HOST and DOOJA_CERT_EMAIL."
  exit 1
fi
if [[ "${PUBLIC_HOST}" =~ ^[0-9.]+$ ]]; then
  echo "Let's Encrypt needs a domain name, not an IP address."
  exit 1
fi

sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot certonly --nginx -d "${PUBLIC_HOST}" --non-interactive --agree-tos -m "${EMAIL}"

sudo sed "s/__PUBLIC_HOST__/${PUBLIC_HOST}/g" "${SCRIPT_DIR}/nginx-dooja-https.conf" | sudo tee /etc/nginx/sites-available/dooja >/dev/null
sudo nginx -t
sudo systemctl reload nginx

if [[ -f /etc/dooja/dooja.env ]]; then
  sudo sed -i "s|^AllowedHosts=.*|AllowedHosts=${PUBLIC_HOST}|" /etc/dooja/dooja.env
  sudo sed -i "s|^Cors__Origins__0=.*|Cors__Origins__0=https://${PUBLIC_HOST}|" /etc/dooja/dooja.env
  sudo systemctl restart dooja.service
fi

echo "HTTPS is configured for ${PUBLIC_HOST}. Confirm from outside: curl -fsS https://${PUBLIC_HOST}/health"
