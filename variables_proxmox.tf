# ============================================
# Variables de Conexión Proxmox
# ============================================

variable "proxmox_api_url" {
  description = "URL base de Proxmox API (ej: https://x.y.z.w:8006/)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "ID del token API (formato: user@realm!tokenname)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Secret del token API"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Deshabilitar validación de certificado TLS. Solo debe ser true en entornos de desarrollo con certificado autofirmado"
  type        = bool
  default     = true
}

# ============================================
# Variables Globales de VM
# ============================================

variable "target_node" {
  description = "Nodo Proxmox donde crear las VMs"
  type        = string
}

variable "template_name" {
  description = "Nombre del template (referencia, no usado por bpg/proxmox)"
  type        = string
}

variable "template_vm_id" {
  description = "VMID del template a clonar. Obtener con: pvesh get /nodes/pve/qemu --output-format json | python3 -m json.tool | grep -B2 'debian'"
  type        = number
}

variable "vm_storage" {
  description = "Storage backend para los discos"
  type        = string
}

variable "vm_disk_size" {
  description = "Tamaño de disco para todas las VMs (en GB)"
  type        = number
  default     = 100
}

variable "enable_qemu_agent" {
  description = "Habilitar QEMU Guest Agent en todas las VMs"
  type        = bool
  default     = false
}

variable "install_qemu_agent" {
  description = "Instalar QEMU Guest Agent automáticamente vía provisioner"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Iniciar VMs automáticamente al arrancar Proxmox"
  type        = bool
  default     = true
}
