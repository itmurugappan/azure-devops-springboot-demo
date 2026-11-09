#!/usr/bin/env bash
# CodeDeploy AfterInstall hook (runs as root on the EC2):
# place the new WAR, fetch the secret from Secrets Manager using the
# instance's IAM role (no stored credentials), and write Tomcat's setenv.sh.
set -euo pipefail

REGION="ap-south-1"
SECRET_ID="app-api-key"
APP_ENV_NAME="DEV"

VERSION="$(cat /tmp/aws-demo-deploy/version.txt 2>/dev/null || echo unknown)"
API_KEY="$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --region "$REGION" --query SecretString --output text)"

cp /tmp/aws-demo-deploy/azure-demo.war /opt/tomcat/webapps/azure-demo.war

cat > /opt/tomcat/bin/setenv.sh <<EOF
export APP_ENV="$APP_ENV_NAME"
export APP_VERSION="$VERSION"
export APP_API_KEY="$API_KEY"
EOF
chmod +x /opt/tomcat/bin/setenv.sh

echo "Installed build $VERSION with secret loaded (length ${#API_KEY})"
