#!/usr/bin/env bash
# CodeDeploy ValidateService hook (runs as root on the EC2):
# poll the app's health endpoint until it answers OK (15 tries x 2s).
set -euo pipefail

for i in $(seq 1 15); do
  if curl -fs http://localhost:8080/azure-demo/health | grep -q '^OK'; then
    echo "Health check OK on try $i"
    exit 0
  fi
  sleep 2
done

echo "Health check FAILED - app did not come up"
exit 1
