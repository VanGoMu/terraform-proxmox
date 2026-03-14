# ============================================
# Outputs - Información de todas las VMs
# ============================================

output "all_vms_summary" {
  description = "Resumen de todas las VMs creadas"
  value = merge(
    { for k, v in module.k8s_master : k => { id = v.vm_id, name = v.vm_name, ip = v.vm_ip } },
    { for k, v in module.k8s_workers : k => { id = v.vm_id, name = v.vm_name, ip = v.vm_ip } },
    { for k, v in module.service_vms : k => { id = v.vm_id, name = v.vm_name, ip = v.vm_ip } }
  )
}

output "k8s_nodes" {
  description = "Estado de los nodos Kubernetes"
  value = merge(
    { for k, v in module.k8s_master : k => v.vm_status },
    { for k, v in module.k8s_workers : k => v.vm_status }
  )
}

output "service_vms" {
  description = "Estado de los servidores de servicios"
  value       = { for k, v in module.service_vms : k => v.vm_status }
}

output "ssh_connections" {
  description = "Comandos SSH para conectar a cada VM"
  value = merge(
    { for k, v in module.k8s_master : k => "ssh ${var.cloud_init_user}@${trimspace(split("/", v.vm_ip)[0])}" },
    { for k, v in module.k8s_workers : k => "ssh ${var.cloud_init_user}@${trimspace(split("/", v.vm_ip)[0])}" },
    { for k, v in module.service_vms : k => "ssh ${var.cloud_init_user}@${trimspace(split("/", v.vm_ip)[0])}" }
  )
}
