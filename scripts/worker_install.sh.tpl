set -euo pipefail
exec &> >(tee /tmp/worker_install.log)

echo '🔧 Configurando nodo worker Kubernetes...'

# Deshabilitar completamente AppArmor
echo '🛡️ Deshabilitando AppArmor...'
sudo systemctl stop apparmor || true
sudo systemctl disable apparmor || true
sudo apt-get purge -y apparmor 2>/dev/null || true

# Configurar GRUB para deshabilitar AppArmor permanentemente
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 apparmor=0 security=none"/' /etc/default/grub
sudo update-grub 2>/dev/null || true

# Deshabilitar swap (requerido por Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Cargar módulos del kernel necesarios para Kubernetes
cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configurar parámetros de red (necesarios para la comunicación de pods)
cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Instalar containerd (runtime de contenedores)
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

# Configurar NFS Client
echo '📁 Configurando cliente NFS...'
sudo apt-get install -y nfs-common
sudo mkdir -p /srv/nfs/kubedata
echo '${master_ip}:/srv/nfs/kubedata /srv/nfs/kubedata nfs defaults,_netdev 0 0' | sudo tee -a /etc/fstab
sudo mount -a
echo '✅ Cliente NFS configurado, montado desde ${master_ip}:/srv/nfs/kubedata'

# Instalar kubeadm, kubelet y kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
echo '✅ Nodo worker listo para unirse al cluster'
