# ============================================
# Variables de Cloud-Init y SSH
# ============================================

variable "ssh_public_key_file" {
  description = "SSH public key file para cloud-init"
  type        = string
  default     = ""
}

variable "ssh_private_key_file" {
  description = "SSH private key file para provisioners (contenido completo o ruta al archivo)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloud_init_user" {
  description = "Usuario para cloud-init en las VMs"
  type        = string
  default     = "debian"
}

variable "cloud_init_password" {
  description = "Contraseña para el usuario cloud-init (se recomienda usar contraseñas fuertes)"
  type        = string
  sensitive   = true
}
