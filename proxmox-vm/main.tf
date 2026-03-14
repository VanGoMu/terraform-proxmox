resource "proxmox_virtual_environment_vm" "vm" {
  node_name   = var.target_node
  vm_id       = var.vm_id
  name        = var.vm_name
  description = var.description

  # Clone from template (requires VM ID, not name)
  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  # QEMU Guest Agent
  agent {
    enabled = var.enable_agent
  }

  # CPU
  cpu {
    cores   = var.cores
    sockets = 1
    type    = "host"
  }

  # Memory (MB)
  memory {
    dedicated = var.memory
  }

  # OS type
  operating_system {
    type = "l26"
  }

  # Main disk
  disk {
    interface    = "scsi0"
    size         = var.disk_size
    datastore_id = var.storage
  }

  # Network
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # Cloud-Init
  initialization {
    datastore_id = var.storage
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
    user_account {
      username = var.cloud_init_user
      password = var.cloud_init_password
      keys     = [var.ssh_key]
    }
    dns {
      servers = [var.nameserver]
    }
  }

  started = true
  on_boot = var.start_on_boot
  tags    = var.tags

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }

  # SSH connection for provisioners
  connection {
    type        = "ssh"
    user        = var.cloud_init_user
    host        = split("/", var.ip_address)[0]
    private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
    password    = var.cloud_init_password
    agent       = false
    timeout     = "15m"
  }

  # Esperar a que cloud-init configure la red y levante SSH antes de conectar
  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      echo "Waiting 180s to VM ${split("/", var.ip_address)[0]} start_on_boot and finish cloud-init..."
      sleep 180
      echo "verifying SSH to ${split("/", var.ip_address)[0]}..."
      for i in $(seq 1 20); do
        if nc -z -w5 ${split("/", var.ip_address)[0]} 22 2>/dev/null; then
          echo "SSH available on attempt $i"
          exit 0
        fi
        echo "Attempt $i/20: SSH not available, waiting 15s..."
        sleep 15
      done
      echo "SSH available (or timeout reached), continuing..."
    EOT
  }

  # Provisioner: custom post-install script
  provisioner "remote-exec" {
    when = create
    inline = compact(concat(
      [
        "echo 'Waiting for cloud-init to finish...'",
        "timeout 120 cloud-init status --wait 2>/dev/null || true",
        "echo 'Cloud-init done, running config scripts...'"
      ],
      var.install_qemu_agent ? [
        "sudo apt-get install -y -q qemu-guest-agent",
        "sudo systemctl enable --now qemu-guest-agent"
      ] : [],
      length(compact(var.post_install_script)) > 0 ? compact(var.post_install_script) : ["echo 'No post_install_script defined'"]
    ))
  }

  # Provisioner: mostrar log del post-install
  provisioner "remote-exec" {
    when = create
    inline = [
      "for f in /tmp/master_install.log /tmp/worker_install.log /tmp/docker_install.log /tmp/services_setup.log; do [ -f \"$f\" ] && echo \"--- $f ---\" && cat \"$f\"; done || true",
    ]
  }

  # Provisioner: join cluster (only if join_cluster_script is defined)
  provisioner "remote-exec" {
    when   = create
    inline = length(compact(var.join_cluster_script)) > 0 ? compact(var.join_cluster_script) : ["echo 'No join_cluster_script defined'"]
  }

  # Provisioner: mostrar log del join (sin valores sensibles, visible en terraform output)
  provisioner "remote-exec" {
    when   = create
    inline = length(compact(var.join_cluster_script)) > 0 ? [
      "echo '--- join_cluster.log ---'",
      "cat /tmp/join_cluster.log 2>/dev/null || echo '(log not found)'",
    ] : ["echo 'Without join_cluster_script, omitting log'"]
  }
}
