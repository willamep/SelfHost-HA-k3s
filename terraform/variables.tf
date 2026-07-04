variable "proxmox_url" {
  description = "Proxmox API URL, e.g. https://192.168.1.10:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token: user@pam!token_name=secret"
  type        = string
  sensitive   = true
}

variable "template_id" {
  description = "VM ID of the Proxmox template"
  type        = number
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