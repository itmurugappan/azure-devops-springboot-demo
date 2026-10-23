#!/usr/bin/env bash
# Run ON the target Tomcat host. Usage:
#   APP_ENV=DEV APP_VERSION=<build> APP_API_KEY=<from Key Vault> bash deploy-war.sh <path-to-azure-demo.war>
# Keeps a timestamped backup of the current WAR first - that backup IS the rollback.
set -euo pipefail

NEW_WAR="${1:?usage: deploy-war.sh <path-to-azure-demo.war>}"
TOMCAT_HOME="/opt/tomcat"
WEBAPPS="$TOMCAT_HOME/webapps"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$TOMCAT_HOME/backup"

# 1) Backup current version (skip on very first deploy)
if [ -f "$WEBAPPS/azure-demo.war" ]; then
  cp "$WEBAPPS/azure-demo.war" "$TOMCAT_HOME/backup/azure-demo-${STAMP}.war"
  echo "Backed up current WAR -> $TOMCAT_HOME/backup/azure-demo-${STAMP}.war"
fi

# 2) Write per-environment settings Tomcat will pass to the app.
#    APP_API_KEY comes from that env's Key Vault via the variable group - never commit it.
cat > "$TOMCAT_HOME/bin/setenv.sh" <<EOF
export APP_ENV="${APP_ENV:-DEV}"
export APP_VERSION="${APP_VERSION:-unknown}"
export APP_API_KEY="${APP_API_KEY:-}"
EOF
chmod +x "$TOMCAT_HOME/bin/setenv.sh"

# 3) Replace the WAR (remove exploded dir so Tomcat re-expands the new one)
systemctl stop tomcat || "$TOMCAT_HOME/bin/shutdown.sh" || true
sleep 3
rm -rf "$WEBAPPS/azure-demo" "$WEBAPPS/azure-demo.war"
cp "$NEW_WAR" "$WEBAPPS/azure-demo.war"
systemctl start tomcat || "$TOMCAT_HOME/bin/startup.sh"

# 4) Health check (Tomcat needs a few seconds to deploy the WAR)
for i in $(seq 1 15); do
  if curl -fsS "http://localhost:8080/azure-demo/health" >/dev/null 2>&1; then
    echo "Health OK: $(curl -s http://localhost:8080/azure-demo/health)"
    exit 0
  fi
  sleep 2
done
echo "ERROR: app did not come up - check $TOMCAT_HOME/logs/catalina.out" >&2
exit 1
