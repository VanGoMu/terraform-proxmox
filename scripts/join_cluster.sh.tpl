set -euo pipefail
exec > /tmp/join_cluster.log 2>&1

echo '🔗 Uniéndose al cluster Kubernetes...'

# Instalar clave SSH para acceder al master
mkdir -p /home/${cloud_user}/.ssh
cat <<'SSHKEY' > /home/${cloud_user}/.ssh/id_rsa
${ssh_private_key}
SSHKEY
chmod 600 /home/${cloud_user}/.ssh/id_rsa
chown ${cloud_user}:${cloud_user} /home/${cloud_user}/.ssh/id_rsa

# Obtener y ejecutar el comando de join desde el master
echo 'Obteniendo y ejecutando join desde el master (${master_ip})...'
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 \
  -i /home/${cloud_user}/.ssh/id_rsa ${cloud_user}@${master_ip} \
  'cat /home/${cloud_user}/join-command.sh' | sudo bash && \
  echo '✅ Nodo worker unido al cluster exitosamente' || \
  { echo '❌ Falló la unión del nodo al cluster'; exit 1; }

# Limpiar clave SSH temporal
rm -f /home/${cloud_user}/.ssh/id_rsa
