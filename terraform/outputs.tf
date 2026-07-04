output "vm_ips" {
  description = "Имя VM → IP (от qemu-guest-agent)"
  value = {
    for vm in proxmox_virtual_environment_vm.vm :
    vm.name => vm.ipv4_addresses[1][0]
  }
}

output "proxmox_nodes" {
  description = "Имя Proxmox-ноды → IP"
  value       = local.proxmox_nodes
}
