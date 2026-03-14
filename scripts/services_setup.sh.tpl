#!/bin/bash
set -euo pipefail
exec &> >(tee /tmp/services_setup.log)

echo 'Actualizando sistema...'
sudo apt-get update
echo '✅ Paquetes actualizados correctamente'
