terraform {
  required_providers {
    proxmox = {
        source = "bpg/proxmox"
        version = "~> 0.88"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.100.68:8006/"
  username = var.proxmox_rootuser
  password = var.proxmox_password
  insecure = true
}
