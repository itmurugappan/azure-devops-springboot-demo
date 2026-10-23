#!/usr/bin/env bash
# Run ON the target Tomcat host. Restores the most recent backup WAR that
# deploy-war.sh saved, restarts Tomcat, and health-checks.
# Azure DevOps equivalent: re-run / redeploy the previous successful release -
# it executes the same deploy with the older artifact.
set -euo pipefail

TOMCAT_HOME="/opt/tomcat"
WEBAPPS="$TOMCAT_HOME/webapps"

LATEST_BACKUP="$(ls -1t "$TOMCAT_HOME/backup/"azure-demo-*.war 2>/dev/null | head -n 1 || true)"
if [ -z "${LATEST_BACKUP}" ]; then
  echo "ERROR: no backup WAR found in $TOMCAT_HOME/backup/" >&2
  exit 1
fi
echo "Rolling back to: $LATEST_BACKUP"

systemctl stop tomcat || "$TOMCAT_HOME/bin/shutdown.sh" || true
sleep 3
rm -rf "$WEBAPPS/azure-demo" "$WEBAPPS/azure-demo.war"
cp "$LATEST_BACKUP" "$WEBAPPS/azure-demo.war"
systemctl start tomcat || "$TOMCAT_HOME/bin/startup.sh"

for i in $(seq 1 15); do
  if curl -fsS "http://localhost:8080/azure-demo/health" >/dev/null 2>&1; then
    echo "Rollback health OK: $(curl -s http://localhost:8080/azure-demo/health)"
    exit 0
  fi
  sleep 2
done
echo "ERROR: rollback did not come up - check $TOMCAT_HOME/logs/catalina.out" >&2
exit 1
