#!/bin/bash

# ==============================================================================
# Script Name: install_nextcloud.sh
# Purpose: Deploy NextCloud + MariaDB for Apex Legal Partners (Project Demo)
# Author: Emma
# We can use this as an example file of a bash script.
# ==============================================================================

# Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "=================================================="
echo "🚀 Starting NextCloud Deployment for Apex Legal..."
echo "=================================================="

# 1. Update the system packages
echo "🔄 Updating system repositories..."
apt-get update -y && apt-get upgrade -y

# 2. Install Docker if it's not already installed
if ! command -v docker &> /dev/null; then
    echo "🐳 Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
else
    echo "✅ Docker is already installed."
fi

# 3. Create a dedicated network for our NextCloud containers
echo "🌐 Creating internal Docker network..."
docker network create nextcloud_network 2>/dev/null || true

# 4. Deploy MariaDB Database Container
echo "🗄️ Launching MariaDB Database Container..."
docker run -d \
  --name nextcloud-db \
  --network nextcloud_network \
  -v nextcloud_db_data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=ApexSecureRootPass2026 \
  -e MYSQL_PASSWORD=ApexDbPassword2026 \
  -e MYSQL_DATABASE=nextcloud \
  -e MYSQL_USER=nextcloud \
  --restart unless-stopped \
  mariadb:10.6 --transaction-isolation=READ-COMMITTED --binlog-format=ROW

# 5. Deploy NextCloud Container (mapped to host port 8080)
echo "☁️ Launching NextCloud Web Application Container..."
docker run -d \
  --name nextcloud-app \
  --network nextcloud_network \
  -p 8080:80 \
  -v nextcloud_app_data:/var/www/html \
  -e MYSQL_HOST=nextcloud-db \
  -e MYSQL_PASSWORD=ApexDbPassword2026 \
  -e MYSQL_DATABASE=nextcloud \
  -e MYSQL_USER=nextcloud \
  --restart unless-stopped \
  nextcloud:latest

echo "=================================================="
echo "🎉 SUCCESS: NextCloud has been deployed!"
echo "👉 Open your browser and go to: http://localhost:8080"
echo "=================================================="