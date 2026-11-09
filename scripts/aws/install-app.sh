#!/usr/bin/env bash
# CodeDeploy AfterInstall hook (runs as root on the EC2):
# place the new WAR, fetch the secret from Secrets Manager using the
# instance's IAM role (no stored credentials), and write Tomcat's setenv.sh.
#
# One bundle serves every environment: CodeDeploy exposes the deployment
# group name to hooks, and the hook picks the environment + secret from it.
# aws-demo-dev-dg -> DEV / app-api-key ; aws-demo-prod-dg -> PROD / app-api-key-prod
set -euo pipefail

REGION="ap-south-1"

if [[ "${DEPLOYMENT_GROUP_NAME:-}" == *prod* ]]; then
  APP_ENV_NAME="PROD"
  SECRET_ID="app-api-key-prod"
else
  APP_ENV_NAME="DEV"
  SECRET_ID="app-api-key"
fi

VERSION="$(cat /tmp/aws-demo-deploy/version.txt 2>/dev/null || echo unknown)"
API_KEY="$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --region "$REGION" --query SecretString --output text)"

cp /tmp/aws-demo-deploy/azure-demo.war /opt/tomcat/webapps/azure-demo.war

cat > /opt/tomcat/bin/setenv.sh <<EOF
export APP_ENV="$APP_ENV_NAME"
export APP_VERSION="$VERSION"
export APP_API_KEY="$API_KEY"
EOF
chmod +x /opt/tomcat/bin/setenv.sh

echo "Installed build $VERSION for $APP_ENV_NAME with secret loaded (length ${#API_KEY})"
