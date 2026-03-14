variable "vm_name" {
  description = "Nombre de la VM"
  type        = string
}

variable "vm_id" {
  description = "ID de la VM (VMID)"
  type        = number
}

variable "target_node" {
  description = "Nodo Proxmox donde crear la VM"
  type        = string
}

variable "template_vm_id" {
  description = "VMID del template a clonar (requerido por bpg/proxmox)"
  type        = number
}

variable "description" {
  description = "Descripción de la VM"
  type        = string
  default     = ""
}

variable "enable_agent" {
  description = "Habilitar QEMU Guest Agent"
  type        = bool
  default     = false
}

variable "cores" {
  description = "Número de cores CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memoria RAM en MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Tamaño del disco en GB (número entero)"
  type        = number
  default     = 50
}

variable "storage" {
  description = "Storage backend para los discos"
  type        = string
}

variable "network_bridge" {
  description = "Bridge de red"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Dirección IP con CIDR (ej: x.y.z.w/24)"
  type        = string
}

variable "gateway" {
  description = "Gateway de red"
  type        = string
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "8.8.8.8"
}

variable "ssh_key" {
  description = "SSH public key para cloud-init"
  type        = string
}

variable "cloud_init_user" {
  description = "Usuario para cloud-init"
  type        = string
  default     = "debian"
}

variable "cloud_init_password" {
  description = "Contraseña para el usuario cloud-init"
  type        = string
  sensitive   = true
}

variable "start_on_boot" {
  description = "Iniciar VM automáticamente al arrancar el host"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para la VM"
  type        = list(string)
  default     = []
}

variable "ssh_private_key" {
  description = "SSH private key para provisioners (opcional, usa ssh-agent si no se proporciona)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "post_install_script" {
  description = "Script personalizado a ejecutar después de crear la VM"
  type        = list(string)
  default     = []
}

variable "join_cluster_script" {
  description = "Script para unir el nodo worker al cluster Kubernetes"
  type        = list(string)
  default     = []
}

variable "install_qemu_agent" {
  description = "Instalar QEMU Guest Agent automáticamente"
  type        = bool
  default     = true
}
