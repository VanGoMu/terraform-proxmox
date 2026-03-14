# ============================================
# Variables de Red Global
# ============================================

variable "vm_subnet_prefix" {
  description = "Prefijo de subred para las IPs de las VMs (ej: 24 para /24)"
  type        = number
  default     = 24
}

variable "network_bridge" {
  description = "Bridge de red para las VMs"
  type        = string
  default     = "vmbr0"
}

variable "vm_gateway" {
  description = "Gateway de red para las VMs"
  type        = string
}

variable "vm_nameserver" {
  description = "DNS nameserver para las VMs"
  type        = string
  default     = "8.8.8.8"
}

