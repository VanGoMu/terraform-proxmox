locals {
  ssh_public_key  = file("${var.ssh_public_key_file}")
  ssh_private_key = file("${var.ssh_private_key_file}")

  master_install_script = [
    "echo '${base64encode(templatefile("${path.module}/scripts/master_install.sh.tpl", {
      master_ip        = var.k8s_nodes["master"].ip
      network_cidr     = var.k8s_network_cidr
      pod_network_cidr = var.k8s_pod_network_cidr
      cloud_user       = var.cloud_init_user
    }))}' | base64 -d | bash"
  ]
  worker_install_script = [
    "echo '${base64encode(templatefile("${path.module}/scripts/worker_install.sh.tpl", {
      master_ip = var.k8s_nodes["master"].ip
    }))}' | base64 -d | bash"
  ]
  join_cluster_script = [
    "echo '${base64encode(templatefile("${path.module}/scripts/join_cluster.sh.tpl", {
      master_ip       = var.k8s_nodes["master"].ip
      cloud_user      = var.cloud_init_user
      ssh_private_key = local.ssh_private_key
    }))}' | base64 -d | bash"
  ]
  docker_install_script = [
    "echo '${base64encode(templatefile("${path.module}/scripts/docker_install.sh.tpl", {}))}' | base64 -d | bash"
  ]
  services_setup_script = [
    "echo '${base64encode(templatefile("${path.module}/scripts/services_setup.sh.tpl", {}))}' | base64 -d | bash"
  ]
}
