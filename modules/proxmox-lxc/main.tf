terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_container" "this" {
  # Identity
  description = var.identity_description
  node_name = var.node_name
  vm_id = var.vm_id

  # Compute
  cpu {
    cores = var.cpu_cores
  }
  memory {
    dedicated = var.memory_dedicated
  }

  # Storage
  disk {
    datastore_id = var.disk_datastore_id
    size = var.disk_size
  }

  # Network
  network_interface {
    name = var.network_interface
    bridge = var.network_bridge
  }
  initialization {
    hostname = var.initialization_hostname
    user_account {
      password = var.initialization_password
    }
    ip_config {
      ipv4 {
        address = var.network_ip_address
        gateway = var.network_gateway
      }
    }
  }

  # OS template
  operating_system {
    template_file_id = var.os_template
    type = "debian"
  }

  # Start on boot
  start_on_boot = var.start_on_boot
}
