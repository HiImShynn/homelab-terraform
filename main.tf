module "proxmox-lxc" {
  source = "./modules/proxmox-lxc"
  for_each = var.lxc_containers
  
  vm_id = each.value["vm_id"]
  identity_description = each.value["identity_description"]
  cpu_cores = each.value["cpu_cores"]
  memory_dedicated = each.value["memory_dedicated"]
  disk_size = each.value["disk_size"]
  network_ip_address = each.value["network_ip_address"]
  initialization_hostname = each.key
  initialization_password = each.value["initialization_password"]
}
