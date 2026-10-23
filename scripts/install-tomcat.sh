#!/usr/bin/env bash
# Run ON each Linux app VM (DEV, SIT, PROD) as a sudo user. Ubuntu 22.04.
# Installs Java 17 + Tomcat 10.1 under /opt/tomcat.
set -euo pipefail

TOMCAT_VERSION="10.1.31"
TOMCAT_HOME="/opt/tomcat"

sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk curl unzip

if [ ! -d "$TOMCAT_HOME" ]; then
  cd /tmp
  curl -fsSLO "https://downloads.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
  sudo mkdir -p "$TOMCAT_HOME"
  sudo tar -xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz" -C "$TOMCAT_HOME" --strip-components=1
fi

sudo mkdir -p "$TOMCAT_HOME/backup"
sudo chmod +x "$TOMCAT_HOME/bin/"*.sh

# systemd service so Tomcat survives reboots and `systemctl restart tomcat` works
sudo tee /etc/systemd/system/tomcat.service >/dev/null <<'EOF'
[Unit]
Description=Apache Tomcat 10
After=network.target

[Service]
Type=forking
User=root
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now tomcat
echo "Tomcat up. Local check:  curl -s http://localhost:8080/  (default Tomcat page)"
echo "Reminder: open NSG inbound 8080 (and 22 for SSH) for this VM in Azure."
