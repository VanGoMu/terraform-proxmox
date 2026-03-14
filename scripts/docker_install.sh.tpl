#!/bin/bash
set -euo pipefail
exec &> >(tee /tmp/docker_install.log)

echo '🐳 Instalando Docker...'
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker debian
sudo systemctl enable docker
echo '✅ Docker instalado correctamente'
