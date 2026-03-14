output "vm_id" {
  description = "ID de la VM creada"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "Nombre de la VM"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "vm_ip" {
  description = "Dirección IP de la VM"
  value       = var.ip_address
}

output "vm_status" {
  description = "Estado de la VM"
  value = {
    id          = proxmox_virtual_environment_vm.vm.vm_id
    name        = proxmox_virtual_environment_vm.vm.name
    target_node = proxmox_virtual_environment_vm.vm.node_name
    cores       = var.cores
    memory      = var.memory
    disk_size   = var.disk_size
    ip_address  = var.ip_address
  }
}
