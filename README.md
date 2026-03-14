# Terraform - Infraestructura Proxmox

Gestión de VMs en Proxmox usando el provider [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) con cloud-init y provisioners.

Crea dos tipos de infraestructura:

- **Cluster Kubernetes** — nodos master y workers configurados automáticamente vía scripts
- **VMs de servicios** — hosts con Docker u otros servicios configurables

## Estructura

```
├── main.tf                    # Instanciación de módulos (k8s_nodes, service_vms)
├── locals.tf                  # Claves SSH y scripts renderizados
├── provider.tf                # Configuración del provider bpg/proxmox
├── outputs.tf                 # Outputs
├── variables.tf               # Índice de archivos de variables
├── variables_proxmox.tf       # Conexión al provider y configuración global de VMs
├── variables_network.tf       # Red: bridge, gateway, nameserver, subnet
├── variables_cloud_init.tf    # Cloud-Init: usuario, contraseña y claves SSH
├── variables_kubernetes.tf    # Cluster Kubernetes: nodos y CIDRs
├── variables_infra_hosts.tf   # VMs de servicios (docker, services, etc.)
├── terraform.tfvars           # Valores de tu instalación (NO commitear)
├── terraform.tfvars.example   # Plantilla con placeholders (commitear)
├── proxmox-vm/                # Módulo reutilizable para una VM
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
└── scripts/                   # Templates de scripts de provisioning
    ├── create_template.sh     # Prerequisito: crea el template Debian en Proxmox
    ├── master_install.sh.tpl
    ├── worker_install.sh.tpl
    ├── join_cluster.sh.tpl
    ├── docker_install.sh.tpl
    └── services_setup.sh.tpl
```

## Requisitos Previos

- Proxmox VE 9 instalado
- Template Debian 13 con cloud-init (ver sección siguiente)
- Token API de Terraform en Proxmox con permisos sobre VMs y datastores
- Terraform >= 1.7

## Crear Template Debian Cloud-Init

**Prerequisito obligatorio antes de `terraform apply`.** El script `scripts/create_template.sh` automatiza la creación del template Debian 13 (Trixie) con cloud-init en Proxmox.

Ejecutar en el nodo Proxmox (como root):

```bash
bash scripts/create_template.sh -i 9000 -s local-lvm -b vmbr0
```

Parámetros disponibles:

| Flag | Default                    | Descripción         |
| ---- | -------------------------- | ------------------- |
| `-i` | `9000`                     | VMID del template   |
| `-s` | `local-lvm`                | Storage backend     |
| `-b` | `vmbr0`                    | Bridge de red       |
| `-n` | `debian-13-cloud-template` | Nombre del template |

El script descarga la imagen oficial desde [cloud.debian.org](https://cloud.debian.org/images/cloud/), configura la VM con `virtio-scsi-pci`, drive cloud-init en `ide2` y QEMU Guest Agent, y la convierte a template. Al finalizar indica los valores exactos a poner en `terraform.tfvars`.

## Configuración

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con los valores de tu instalación.

## Uso

```bash
# Inicializar providers
terraform init

# Ver plan de cambios
terraform plan

# Aplicar toda la infraestructura
terraform apply

# Aplicar solo el cluster Kubernetes (master y workers)
terraform apply -target=module.k8s_master
terraform apply -target=module.k8s_workers

# Aplicar solo las VMs de servicios
terraform apply -target=module.service_vms

# Destruir una VM específica
terraform destroy -target='module.k8s_workers["worker1"]'
```

## Referencias

- [bpg/proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Proxmox VE Docs](https://pve.proxmox.com/pve-docs/)
- [Debian Cloud Images](https://cloud.debian.org/images/cloud/)
