# Terraform Hands-On Exercises: Complete Recap

## What We Built

Five new LXC containers on your Proxmox homelab (darwin-k8plus) using modular,
data-driven Terraform:

| ID  | Name           | Purpose                          | IP               |
|-----|----------------|----------------------------------|------------------|
| 500 | mysql-dev      | Database for development         | 192.168.100.50   |
| 501 | dev-workspace  | Clean coding environment         | 192.168.100.51   |
| 502 | gitea          | Self-hosted Git                  | 192.168.100.52   |
| 503 | semaphore      | Ansible GUI/scheduler            | 192.168.100.53   |
| 504 | syslog         | Centralized logging (rsyslog)    | 192.168.100.54   |

These sit alongside your existing containers (100-400 range) on the
192.168.100.0/24 network.


---


## Project Structure

Six files, each with one job. Data flows top to bottom, never backwards.

```
homelab-terraform/
    providers.tf              <-- "What provider do I use, and how do I connect?"
    variables.tf              <-- "What inputs does the root module accept?"
    terraform.tfvars          <-- "Here are the actual values" (GITIGNORED)
    main.tf                   <-- "Call the module once per container"
    outputs.tf                <-- "Display results after apply"
    modules/
        proxmox-lxc/
            main.tf           <-- "The actual resource that talks to Proxmox"
            variables.tf      <-- "What inputs does this module accept?"
            outputs.tf        <-- "What values does this module expose?"
    .gitignore
```


---


## Data Flow (Follow One Container: "mysql-dev")

```
Step 1: terraform.tfvars (you define the data)

    "mysql-dev" = {
        vm_id = 500
        cpu_cores = 2
        memory_dedicated = 1024
        ...
    }

        |
        v

Step 2: Root main.tf reads it with for_each

    for_each = var.lxc_containers
    each.key   = "mysql-dev"
    each.value = { vm_id = 500, cpu_cores = 2, ... }

        |
        v

Step 3: Root main.tf passes values into the module

    vm_id = each.value["vm_id"]             --> becomes var.vm_id = 500
    initialization_hostname = each.key      --> becomes var.initialization_hostname = "mysql-dev"
    cpu_cores = each.value["cpu_cores"]     --> becomes var.cpu_cores = 2

        |
        v

Step 4: Module main.tf uses variables in the resource

    vm_id = var.vm_id                       --> Proxmox creates container ID 500
    initialization { hostname = var... }    --> hostname is "mysql-dev"
    cpu { cores = var.cpu_cores }           --> container gets 2 cores

        |
        v

Step 5: Proxmox API call

    "Create container 500 named mysql-dev with 2 cores"
```

Terraform repeats steps 2-5 for each entry in the map. Five entries = five containers.


---


## The Five Essential Blocks

Everything in Terraform uses only these five blocks. Every other block
(output, locals, data) is supporting cast.

### 1. terraform {} -- "What tools do I need?"

Runs once. Declares which providers to download. You rarely touch it after setup.

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.88"
    }
  }
}
```

### 2. provider {} -- "How do I connect?"

Credentials and endpoint. One per platform.

```hcl
provider "proxmox" {
  endpoint = "https://192.168.100.68:8006/"
  username = var.proxmox_rootuser
  password = var.proxmox_password
  insecure = true
}
```

### 3. variable {} -- "What inputs do I accept?"

A slot that waits for a value. Does nothing on its own.

```hcl
variable "cpu_cores" {
  type    = number
  default = 2
}
```

### 4. resource {} -- "What do I create?"

THE ONLY BLOCK THAT TALKS TO PROXMOX. Every other block exists to support
this one.

```hcl
resource "proxmox_virtual_environment_container" "this" {
  vm_id = var.vm_id
}
```

### 5. module {} -- "Run that folder's code with these inputs."

Calls another set of .tf files and passes values in.

```hcl
module "proxmox-lxc" {
  source    = "./modules/proxmox-lxc"
  cpu_cores = 2
}
```


---


## Final Code (All Files)

### .gitignore

```
*.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

Why each entry:
- *.tfvars -- contains credentials (API passwords, container passwords)
- *.tfstate -- contains full resource config including secrets, is the source
  of truth for what exists (must not diverge between team members)
- *.tfstate.backup -- same as above
- .terraform/ -- downloaded provider binaries (like node_modules/ or .venv/)


### providers.tf (root)

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
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
```

Key decisions:
- https not http (Proxmox API uses TLS on port 8006)
- insecure = true because homelab uses self-signed certs
  (in production, use CA-signed certs and set insecure = false)
- credentials use variables, not hardcoded values


### variables.tf (root)

```hcl
variable "proxmox_rootuser" {
  description = "Username for Proxmox API"
  type        = string
}

variable "proxmox_password" {
  description = "Password for Proxmox API"
  type        = string
  sensitive   = true
}

variable "lxc_containers" {
  description = "Map of LXC containers to create"
  type = map(object({
    vm_id                  = number
    identity_description   = string
    cpu_cores              = number
    memory_dedicated       = number
    disk_size              = number
    network_ip_address     = string
    initialization_password = string
  }))
}
```

Key decisions:
- lxc_containers is a map(object({})) so we can use for_each
- map key becomes the container hostname (no need for separate hostname field)
- only fields that vary per container are in the object
- fields with sensible defaults (gateway, bridge, template) stay in the module


### terraform.tfvars (root -- GITIGNORED)

```hcl
proxmox_rootuser = "root@pam"
proxmox_password = "your-password-here"

lxc_containers = {
  "mysql-dev" = {
    vm_id                  = 500
    identity_description   = "MySQL database container."
    cpu_cores              = 2
    memory_dedicated       = 1024
    disk_size              = 10
    network_ip_address     = "192.168.100.50/24"
    initialization_password = "changeme"
  }
  "dev-workspace" = {
    vm_id                  = 501
    identity_description   = "Workspace container for projects."
    cpu_cores              = 2
    memory_dedicated       = 2048
    disk_size              = 10
    network_ip_address     = "192.168.100.51/24"
    initialization_password = "changeme"
  }
  "gitea" = {
    vm_id                  = 502
    identity_description   = "Version control container."
    cpu_cores              = 1
    memory_dedicated       = 512
    disk_size              = 5
    network_ip_address     = "192.168.100.52/24"
    initialization_password = "changeme"
  }
  "semaphore" = {
    vm_id                  = 503
    identity_description   = "Ansible GUI/Scheduler container."
    cpu_cores              = 2
    memory_dedicated       = 512
    disk_size              = 5
    network_ip_address     = "192.168.100.53/24"
    initialization_password = "changeme"
  }
  "syslog" = {
    vm_id                  = 504
    identity_description   = "Centralised logging (rsyslog) container."
    cpu_cores              = 1
    memory_dedicated       = 512
    disk_size              = 5
    network_ip_address     = "192.168.100.54/24"
    initialization_password = "changeme"
  }
}
```


### main.tf (root)

```hcl
module "proxmox-lxc" {
  source   = "./modules/proxmox-lxc"
  for_each = var.lxc_containers

  vm_id                  = each.value["vm_id"]
  identity_description   = each.value["identity_description"]
  cpu_cores              = each.value["cpu_cores"]
  memory_dedicated       = each.value["memory_dedicated"]
  disk_size              = each.value["disk_size"]
  network_ip_address     = each.value["network_ip_address"]
  initialization_hostname = each.key
  initialization_password = each.value["initialization_password"]
}
```

Key decisions:
- initialization_hostname uses each.key (the map key) to avoid duplicating
  the name in the object and the key
- for_each creates one module instance per map entry
- Terraform tracks each as module.proxmox-lxc["mysql-dev"], etc.


### outputs.tf (root)

```hcl
output "container_ips" {
  value = {
    for name, instance in module.proxmox-lxc :
    name => instance.container_ip
  }
}
```


### modules/proxmox-lxc/variables.tf

```hcl
# Identity
variable "vm_id" {
  description = "Unique ID for the container."
  type        = number
}

variable "node_name" {
  description = "Name of the node in your datacenter."
  type        = string
  default     = "darwin-k8plus"
}

variable "identity_description" {
  description = "Description of the container."
  type        = string
  default     = "Debian LXC."
}

# Compute
variable "cpu_cores" {
  description = "The number of cores in the container."
  type        = number
  default     = 2
}

variable "memory_dedicated" {
  description = "Size of the RAM in MB."
  type        = number
  default     = 512
}

# Storage
variable "disk_size" {
  description = "Size of the disk in GB."
  type        = number
  default     = 5
}

variable "disk_datastore_id" {
  description = "ID of the datastore in your node."
  type        = string
  default     = "local-lvm"
}

# Network
variable "network_interface" {
  description = "The virtual interface for the container."
  type        = string
  default     = "eth0"
}

variable "network_ip_address" {
  description = "The IP address and subnet in CIDR for the container."
  type        = string
}

variable "network_gateway" {
  description = "The default gateway for the container."
  type        = string
  default     = "192.168.100.1"
}

variable "network_bridge" {
  description = "The virtual bridge (switch) that the container connects to."
  type        = string
  default     = "vmbr0"
}

# Initialization
variable "initialization_hostname" {
  description = "The hostname for the container."
  type        = string
}

variable "initialization_password" {
  description = "The root password for the container."
  type        = string
  sensitive   = true
}

# OS Template
variable "os_template" {
  description = "The template for the container."
  type        = string
  default     = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
}

# Start on boot
variable "start_on_boot" {
  description = "Allow the container to start on boot."
  type        = bool
  default     = true
}
```

Key decisions:
- Variables with defaults: values that are the same across most containers
  (node_name, gateway, bridge, template, datastore, etc.)
- Variables without defaults: values unique to each container
  (vm_id, ip_address, hostname, password) -- caller MUST provide these
- initialization_password is sensitive = true (masked in plan output)


### modules/proxmox-lxc/main.tf

```hcl
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
  node_name   = var.node_name
  vm_id       = var.vm_id

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
    size         = var.disk_size
  }

  # Network
  network_interface {
    name   = var.network_interface
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
    type             = "debian"
  }

  # Start on boot
  start_on_boot = var.start_on_boot
}
```

Key decisions:
- required_providers block is needed so the module knows "proxmox" means
  "bpg/proxmox", not "hashicorp/proxmox"
- resource name "this" is convention for single-resource modules


### modules/proxmox-lxc/outputs.tf

```hcl
output "container_ip" {
  value       = var.network_ip_address
  description = "IP address of the container."
}
```


---


## Mistakes Made and Lessons Learned

### Exercise 1: .gitignore

MISTAKE: Thought .tfstate should be excluded because of "duplicate files"
LESSON: The real reason is DIVERGENCE. If two people have different state
files, Terraform thinks resources don't exist when they do, leading to
conflicts. State must be a single shared source of truth.

LESSON: For teams, use a remote backend (S3 + DynamoDB, Terraform Cloud)
with state locking. Git doesn't support locking -- two people can read
and modify state simultaneously, causing overwrites.

LESSON: .terraform/ is excluded for the same reason as node_modules/ or
.venv/ -- it's downloaded dependencies, not source code.


### Exercise 2: Provider Config

MISTAKE: Used http:// instead of https:// for endpoint
LESSON: Proxmox API runs on TLS (port 8006). That's why you see certificate
warnings in the browser.

MISTAKE: Hardcoded username and password in providers.tf
LESSON: Credentials go in variables, actual values go in terraform.tfvars
(which is gitignored).

LESSON: insecure = true bypasses TLS certificate verification. Safe in
homelab (self-signed certs, you own the network). Dangerous in production
(enables man-in-the-middle attacks). Production uses CA-signed certs.

LESSON: Provider source format is "namespace/provider" (e.g., "bpg/proxmox"),
not just "proxmox".


### Exercise 3: Module Variables

MISTAKE: Set vm_id type to string instead of number
LESSON: Proxmox container IDs are integers. Match the type to the data.

MISTAKE: Put /24 on the gateway (192.168.100.1/24)
LESSON: Gateway is just an IP address (the router). The /24 subnet mask
belongs on the container's own IP address.

MISTAKE: Tried to set default = var.proxmox_rootuser in a variable block
LESSON: Variable defaults must be static literal values. You cannot reference
other variables. Also, the Proxmox API password and a container's root
password are two completely different credentials.

MISTAKE: Default disk size of 1 GB
LESSON: Think about what the container actually runs. MySQL and Gitea
need more than 1 GB. Default was changed to 5 GB.


### Exercise 7: Init and Plan

MISTAKE: terraform init failed -- module tried to use hashicorp/proxmox
LESSON: Each module needs its own required_providers block declaring the
provider source. Without it, Terraform assumes the default namespace
(hashicorp/) for any provider name it sees.

LESSON: You don't need to explicitly pass providers in the module block
(providers = { proxmox = proxmox }) when parent and child use the same
provider name. Terraform handles it automatically.


---


## Key Concepts to Remember

### Terraform Core Loop
```
terraform init      --> Download providers
terraform validate  --> Check syntax
terraform plan      --> Dry run ("here's what I'd change")
terraform apply     --> Make it real
terraform destroy   --> Tear it all down
```

### Data Separation Principle
.tf files define STRUCTURE. Variables supply VALUES.
Change what you build by editing terraform.tfvars -- no code changes needed.

### for_each Pattern
Define a map variable. Use for_each to create one resource/module per entry.
each.key = map key. each.value = the object for that entry.

### Module Pattern
Write the resource once in a module folder. Call it from root with different
values. One module, many instances.

### Variable Precedence (lowest to highest)
1. Default value in variables.tf
2. terraform.tfvars
3. *.auto.tfvars
4. -var flag on CLI
5. TF_VAR_name environment variable

### sensitive = true
Masks values in plan/apply output. Use for passwords, tokens, private keys.
Does NOT encrypt the state file -- secrets still exist there in plain text.

### State File
- Terraform's memory of what exists in the real world
- Maps resource addresses to real infrastructure IDs
- Never edit manually, never commit to Git
- For teams: use remote backend with state locking


---


## Terraform Commands Reference

```bash
terraform init                     # Download providers, initialize
terraform validate                 # Check syntax errors
terraform plan                     # Preview changes (dry run)
terraform plan -out=tfplan         # Save plan to file
terraform apply                    # Apply changes (prompts yes/no)
terraform apply tfplan             # Apply saved plan (no prompt)
terraform apply -auto-approve      # Skip confirmation (be careful)
terraform destroy                  # Remove all managed resources
terraform fmt                      # Auto-format .tf files
terraform state list               # Show all tracked resources
terraform state show <resource>    # Show details of one resource
terraform output                   # Display output values
```


---


## What's Next: Phase 2 (Ansible)

Terraform created the containers. Ansible will configure them:
- Install MySQL and set up databases
- Deploy Gitea for self-hosted Git
- Set up Semaphore as Ansible GUI
- Wire syslog forwarding from all containers to the syslog server
- Manage secrets with Ansible Vault (replacing the shared passwords in tfvars)

Ansible concepts to learn:
- Inventory (targeting your containers)
- Playbooks (task definitions)
- Roles (reusable config packages)
- Templates with Jinja2 (dynamic config files)
- Handlers (restart services on config changes)
- Vault (encrypted secrets)