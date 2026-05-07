output "container_ips" {
  value = {
    for name, instance in module.proxmox-lxc :
    name => instance.container_ip
  }
}
