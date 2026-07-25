#!/usr/bin/env bash
set -euo pipefail

echo "=================================="
echo "🚀 PROVISION SERVICE"
echo "=================================="

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
  nginx \
  docker.io \
  docker-compose

systemctl enable nginx
systemctl enable docker

systemctl start nginx
systemctl start docker

echo
echo "🐳 Docker Version"
docker --version || true

echo
echo "🌐 Nginx Version"
nginx -v || true

echo
echo "✅ SERVICE PROVISION DONE"