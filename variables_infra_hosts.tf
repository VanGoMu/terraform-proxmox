# ============================================
# Variables de Servidores de Servicios
# ============================================

variable "service_vms" {
  description = "Configuración de los servidores de servicios (docker, services, etc.)"
  type = map(object({
    vm_name     = string
    vm_id       = number
    ip          = string
    cores       = number
    memory      = number
    description = string
    tags        = list(string)
    script_type = string # "docker" o "services"
  }))
}
