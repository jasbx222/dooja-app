#!/usr/bin/env bash
# Restore the newest publish backup and restart Dooja. Does not touch the SQLite file.
set -euo pipefail

latest="$(sudo ls -1t /var/backups/dooja/dooja-*.tar.gz 2>/dev/null | head -n 1 || true)"
if [[ -z "${latest}" ]]; then
  echo "No backup in /var/backups/dooja."
  exit 1
fi

echo "Restoring ${latest}"
sudo find /opt/dooja -mindepth 1 -maxdepth 1 -exec rm -rf {} +
sudo tar -C /opt/dooja -xzf "${latest}"
sudo chown -R dooja:dooja /opt/dooja
sudo systemctl restart dooja.service

for _ in 1 2 3 4 5 6 7 8 9 10; do
  if curl -fsS http://127.0.0.1:5080/health; then
    echo
    echo "Rollback is serving."
    exit 0
  fi
  sleep 2
done

echo "Rollback did not answer /health. Check: journalctl -u dooja -n 80 --no-pager"
exit 1
