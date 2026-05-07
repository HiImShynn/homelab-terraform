# Identity (Name, ID, Description)
variable "vm_id" {
  description = "Unique ID for the container."
  type = number
}

variable "node_name" {
  description = "Name of the node in your datacenter."
  type = string
  default = "darwin-k8plus"
}

variable "identity_description" {
  description = "Description of the container."
  type = string
  default = "Debian LXC."
}

# Compute (Cores, Memory)
variable "cpu_cores" {
  description = "The number of cores in the container."
  type = number
  default = 2
}

variable "memory_dedicated" {
  description = "Size of the RAM in MB."
  type = number
  default = 512
}

# Storage (Disk size, Datastore)
variable "disk_size" {
  description = "Size of the disk in GB."
  type = number
  default = 5
}

variable "disk_datastore_id" {
  description = "ID of the datastore in your node."
  type = string
  default = "local-lvm"
}

# Network (Interface, IP address, Gateway, Bridge)
variable "network_interface" {
  description = "The virtual interface for the container."
  type = string
  default = "eth0"
}

variable "network_ip_address" {
  description = "The IP address and subnet in CIDR for the container."
  type = string
}

variable "network_gateway" {
  description = "The default gateway for the container."
  type = string
  default = "192.168.100.1"
}

variable "network_bridge" {
  description = "The virtual bridge (switch) that the container connects to."
  type = string
  default = "vmbr0"
}

# Configuration
variable "initialization_password" {
  description = "The password for the container root user."
  type = string
  sensitive = true
}

variable "initialization_hostname" {
  description = "The hostname for the container."
  type = string
}

# OS Template
variable "os_template" {
  description = "The template for the container."
  type = string
  default = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
}

# Start on boot
variable "start_on_boot" {
  description = "Allow the container to start on boot."
  type = bool
  default = true
}
