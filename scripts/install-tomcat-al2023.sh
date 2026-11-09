#!/usr/bin/env bash
# Run ON the AWS EC2 app instance as a sudo user. Amazon Linux 2023.
# AWS twin of install-tomcat.sh (Ubuntu): Java 17 (Amazon Corretto) + Tomcat 10.1 under /opt/tomcat.
set -euo pipefail

TOMCAT_VERSION="10.1.31"
TOMCAT_HOME="/opt/tomcat"

sudo dnf install -y java-17-amazon-corretto-devel unzip

JAVA_HOME_RESOLVED="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
echo "JAVA_HOME resolved to: $JAVA_HOME_RESOLVED"

if [ ! -d "$TOMCAT_HOME" ]; then
  cd /tmp
  curl -fsSLO "https://archive.apache.org/dist/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
  sudo mkdir -p "$TOMCAT_HOME"
  sudo tar -xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz" -C "$TOMCAT_HOME" --strip-components=1
fi

sudo mkdir -p "$TOMCAT_HOME/backup"
# Tar extracted as root can be unreadable by the ssh user; make it readable and
# expand the *.sh glob inside a root shell (plain sudo chmod fails on the glob).
sudo chmod -R a+rX "$TOMCAT_HOME"
sudo sh -c 'chmod +x /opt/tomcat/bin/*.sh'

# systemd service so Tomcat survives reboots and `systemctl restart tomcat` works
sudo tee /etc/systemd/system/tomcat.service >/dev/null <<'EOF'
[Unit]
Description=Apache Tomcat 10
After=network.target

[Service]
Type=forking
User=root
Environment="JAVA_HOME=__JAVA_HOME__"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo sed -i "s|__JAVA_HOME__|$JAVA_HOME_RESOLVED|" /etc/systemd/system/tomcat.service

sudo systemctl daemon-reload
sudo systemctl enable --now tomcat
echo "Tomcat up. Local check:  curl -s http://localhost:8080/  (default Tomcat page)"
echo "Reminder: security group must allow inbound 8080 (and 22 for SSH) from your IP."
