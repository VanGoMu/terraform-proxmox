set -euo pipefail
exec &> >(tee /tmp/master_install.log)

echo '🔧 Configurando nodo maestro Kubernetes con Cilium...'

# Deshabilitar completamente AppArmor
echo '🛡️ Deshabilitando AppArmor...'
sudo systemctl stop apparmor || true
sudo systemctl disable apparmor || true
sudo apt-get purge -y apparmor 2>/dev/null || true

# Configurar GRUB para deshabilitar AppArmor permanentemente
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 apparmor=0 security=none"/' /etc/default/grub
sudo update-grub 2>/dev/null || true

# Deshabilitar swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Cargar módulos del kernel
cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configurar parámetros de sysctl
cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Instalar containerd
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd /opt/cni/bin /etc/cni/net.d
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo sed -i 's|bin_dir = "/usr/lib/cni"|bin_dir = "/opt/cni/bin"|' /etc/containerd/config.toml
sudo sed -i 's|conf_dir = "/etc/cni/net.d"|conf_dir = "/etc/cni/net.d"|' /etc/containerd/config.toml
sudo sed -i '/\[plugins\."io\.containerd\.grpc\.v1\.cri"\]/,/^\[/ { s/apparmor_profile = .*/apparmor_profile = "unconfined"/ }' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Configurar NFS Server
echo '📁 Configurando servidor NFS...'
sudo apt-get install -y nfs-kernel-server nfs-common
sudo mkdir -p /srv/nfs/kubedata
sudo chown nobody:nogroup /srv/nfs/kubedata
sudo chmod 777 /srv/nfs/kubedata
echo '/srv/nfs/kubedata ${network_cidr}(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
echo '✅ Servidor NFS configurado en /srv/nfs/kubedata'

# Instalar kubeadm, kubelet y kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Configurar imagen de sandbox para containerd
sudo sed -i 's|sandbox_image = "registry.k8s.io/pause:3\..*"|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml
sudo systemctl restart containerd

# Inicializar cluster
sudo kubeadm init --pod-network-cidr=${pod_network_cidr} --apiserver-advertise-address=${master_ip}

# Configurar kubectl para el usuario
mkdir -p /home/${cloud_user}/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/${cloud_user}/.kube/config
sudo chown ${cloud_user}:${cloud_user} /home/${cloud_user}/.kube/config

# Instalar Cilium CLI
export KUBECONFIG=/home/${cloud_user}/.kube/config
CILIUM_CLI_VERSION=$(curl -fsSL https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -fsSL -o cilium-linux-amd64.tar.gz \
  "https://github.com/cilium/cilium-cli/releases/download/$${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz"
curl -fsSL -o cilium-linux-amd64.tar.gz.sha256sum \
  "https://github.com/cilium/cilium-cli/releases/download/$${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz.sha256sum"
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz cilium-linux-amd64.tar.gz.sha256sum

# Crear directorios CNI
sudo mkdir -p /opt/cni/bin /etc/cni/net.d

# Instalar Cilium CNI
echo '🔵 Instalando Cilium...'
CILIUM_VERSION="1.17.2"
cilium install \
  --version "$${CILIUM_VERSION}" \
  --set cni.binPath=/opt/cni/bin \
  --set cni.confPath=/etc/cni/net.d \
  --set operator.replicas=1
echo '✅ Cilium desplegado, esperando pods...'

# Esperar a que los pods de Cilium existan y estén listos
RETRY=0
until kubectl get pods -n kube-system -l k8s-app=cilium 2>/dev/null | grep -q cilium || [ "$${RETRY}" -eq 30 ]; do
  echo "Intento $${RETRY}: Esperando que se creen los pods de Cilium..."
  RETRY=$((RETRY+1))
  sleep 10
done

kubectl wait --for=condition=ready pod -l k8s-app=cilium -n kube-system --timeout=300s
echo '✅ Instalación de Cilium completada'
cilium status || true

# Guardar join command para los workers
sudo kubeadm token create --print-join-command > /home/${cloud_user}/join-command.sh
sudo chown ${cloud_user}:${cloud_user} /home/${cloud_user}/join-command.sh
sudo chmod +x /home/${cloud_user}/join-command.sh
echo '✅ Nodo maestro Kubernetes configurado correctamente con Cilium'
echo '📋 Para unir workers, ejecuta en cada nodo:'
echo '   scp debian@${master_ip}:/home/${cloud_user}/join-command.sh . && sudo bash join-command.sh'
