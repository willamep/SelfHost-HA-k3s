variable "proxmox_url" {
  description = "Proxmox API URL, e.g. https://192.168.1.10:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token: user@pam!token_name=secret"
  type        = string
  sensitive   = true
}

variable "template_ids" {
  description = "VM ID локального шаблона для каждой Proxmox-ноды"
  type        = map(number)

  validation {
    condition     = length(var.template_ids) == 3 && alltrue([for key in ["0", "1", "2"] : contains(keys(var.template_ids), key)])
    error_message = "template_ids должен содержать ключи 0, 1 и 2."
  }

  validation {
    condition     = length(distinct(values(var.template_ids))) == 3
    error_message = "Каждая Proxmox-нода должна использовать шаблон с уникальным VM ID."
  }
}

variable "node_name_0" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "node_name_1" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "node_name_2" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "node_0_ip" {
  description = "IP node"
  type        = string
}

variable "node_1_ip" {
  description = "IP node"
  type        = string
}

variable "node_2_ip" {
  description = "IP node"
  type        = string
}

variable "vm_password" {
  description = "Password for the ansible user on all VMs"
  type        = string
  sensitive   = true
}

variable "gateway" {
  description = "Шлюз для статических IP (сеть 192.168.3.0/24)"
  type        = string
  default     = "192.168.3.1"
}

variable "environment" {
  description = "Окружение конфигурации: dev использует workspace dev, prod — default"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment должен быть равен dev или prod."
  }
}

variable "vms" {
  description = "VM, создаваемые в выбранном окружении"
  type = map(object({
    name      = string
    vm_id     = number
    node      = number
    cores     = number
    memory    = number
    disk      = number
    data_disk = optional(number)
    role      = string
  }))

  validation {
    condition     = alltrue([for vm in values(var.vms) : contains([0, 1, 2], vm.node)])
    error_message = "Поле node каждой VM должно быть равно 0, 1 или 2."
  }

  validation {
    condition     = length(distinct([for vm in values(var.vms) : vm.vm_id])) == length(var.vms)
    error_message = "vm_id должны быть уникальны внутри окружения."
  }

  validation {
    condition = (
      length([for vm in values(var.vms) : vm if vm.role == "servers"]) == 3 &&
      length(distinct([for vm in values(var.vms) : vm.node if vm.role == "servers"])) == 3 &&
      length([for vm in values(var.vms) : vm if vm.role == "ci_agents"]) == 1
    )
    error_message = "Топология k3s должна содержать три server-ноды на разных Proxmox-нодах и один CI agent."
  }
}

variable "static_ips" {
  description = "Статические IPv4-адреса VM; отсутствующие ключи используют DHCP"
  type        = map(string)
  default     = {}
}
