variable "proxmox_rootuser" {
  description = "username for root user"
  sensitive = true
  type = string
}

variable "proxmox_password" {
  description = "password for root user."
  sensitive = true
  type = string
}

variable "lxc_containers" {
  description = "LXC Object definition."
  type = map(object({
    # Identity
    vm_id = number
    identity_description = string
    
    # Compute
    cpu_cores = number
    memory_dedicated = number

    # Storage
    disk_size = number

    # Network
    network_ip_address = string

    # Configuration
    initialization_hostname = string
    initialization_password = string
  }))
}
