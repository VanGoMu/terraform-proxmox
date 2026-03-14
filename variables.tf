# Las variables están organizadas por función en archivos separados:
#
#   variables_proxmox.tf     - Conexión al provider y configuración global de VMs
#   variables_network.tf     - Red: bridge, gateway, nameserver e IPs de cada host
#   variables_cloud_init.tf  - Cloud-Init: usuario, contraseña y claves SSH
#   variables_kubernetes.tf  - Cluster Kubernetes: CIDRs y recursos de nodos
#   variables_infra_hosts.tf - Servidores de servicios (docker, services, etc.)
