# ============================================
# Cluster Kubernetes
# ============================================

module "k8s_master" {
  for_each = { for k, v in var.k8s_nodes : k => v if v.role == "master" }
  source   = "./proxmox-vm"

  vm_name        = each.value.vm_name
  vm_id          = each.value.vm_id
  target_node    = var.target_node
  template_vm_id = var.template_vm_id
  description    = var.k8s_description

  cores     = each.value.cores
  memory    = each.value.memory
  disk_size = var.vm_disk_size
  storage   = var.vm_storage

  ip_address     = "${each.value.ip}/${var.vm_subnet_prefix}"
  gateway        = var.vm_gateway
  nameserver     = var.vm_nameserver
  ssh_key        = local.ssh_public_key
  network_bridge = var.network_bridge

  cloud_init_user     = var.cloud_init_user
  cloud_init_password = var.cloud_init_password
  enable_agent        = var.enable_qemu_agent
  start_on_boot       = var.start_on_boot

  ssh_private_key    = local.ssh_private_key
  install_qemu_agent = var.install_qemu_agent

  post_install_script = local.master_install_script
  join_cluster_script = []

  tags = var.k8s_tags
}

module "k8s_workers" {
  for_each   = { for k, v in var.k8s_nodes : k => v if v.role == "worker" }
  source     = "./proxmox-vm"
  depends_on = [module.k8s_master]

  vm_name        = each.value.vm_name
  vm_id          = each.value.vm_id
  target_node    = var.target_node
  template_vm_id = var.template_vm_id
  description    = var.k8s_description

  cores     = each.value.cores
  memory    = each.value.memory
  disk_size = var.vm_disk_size
  storage   = var.vm_storage

  ip_address     = "${each.value.ip}/${var.vm_subnet_prefix}"
  gateway        = var.vm_gateway
  nameserver     = var.vm_nameserver
  ssh_key        = local.ssh_public_key
  network_bridge = var.network_bridge

  cloud_init_user     = var.cloud_init_user
  cloud_init_password = var.cloud_init_password
  enable_agent        = var.enable_qemu_agent
  start_on_boot       = var.start_on_boot

  ssh_private_key    = local.ssh_private_key
  install_qemu_agent = var.install_qemu_agent

  post_install_script = local.worker_install_script
  join_cluster_script = local.join_cluster_script

  tags = var.k8s_tags
}

# ============================================
# Servidores de Servicios
# ============================================

module "service_vms" {
  for_each = var.service_vms
  source   = "./proxmox-vm"

  vm_name        = each.value.vm_name
  vm_id          = each.value.vm_id
  target_node    = var.target_node
  template_vm_id = var.template_vm_id
  description    = each.value.description

  cores     = each.value.cores
  memory    = each.value.memory
  disk_size = var.vm_disk_size
  storage   = var.vm_storage

  ip_address     = "${each.value.ip}/${var.vm_subnet_prefix}"
  gateway        = var.vm_gateway
  nameserver     = var.vm_nameserver
  ssh_key        = local.ssh_public_key
  network_bridge = var.network_bridge

  cloud_init_user     = var.cloud_init_user
  cloud_init_password = var.cloud_init_password
  enable_agent        = var.enable_qemu_agent
  start_on_boot       = var.start_on_boot

  ssh_private_key    = local.ssh_private_key
  install_qemu_agent = var.install_qemu_agent

  post_install_script = each.value.script_type == "docker" ? local.docker_install_script : local.services_setup_script

  tags = each.value.tags
}
