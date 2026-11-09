#!/usr/bin/env bash
# CodeDeploy ApplicationStart hook (runs as root on the EC2).
set -euo pipefail

systemctl start tomcat
