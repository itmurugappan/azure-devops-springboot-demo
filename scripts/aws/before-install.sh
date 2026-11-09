#!/usr/bin/env bash
# CodeDeploy BeforeInstall hook (runs as root on the EC2):
# stop Tomcat, back up the current WAR, clear the old app and staging dir.
set -euo pipefail

systemctl stop tomcat 2>/dev/null || true

if [ -f /opt/tomcat/webapps/azure-demo.war ]; then
  mkdir -p /opt/tomcat/backup
  cp /opt/tomcat/webapps/azure-demo.war "/opt/tomcat/backup/azure-demo-$(date +%Y%m%d%H%M%S).war"
fi

rm -rf /opt/tomcat/webapps/azure-demo /opt/tomcat/webapps/azure-demo.war /tmp/aws-demo-deploy
mkdir -p /tmp/aws-demo-deploy
