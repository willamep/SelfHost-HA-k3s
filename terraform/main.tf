# ───────────────────────────────────────────────────────────────────────
# Общая конфигурация VM для dev и prod.
# Параметры конкретного окружения передаются через config/<env>.tfvars.
# ───────────────────────────────────────────────────────────────────────

locals {
  proxmox_node_names = {
    "0" = var.node_name_0
    "1" = var.node_name_1
    "2" = var.node_name_2
  }

  vms = {
    for key, cfg in var.vms : key => merge(cfg, {
      node_name = local.proxmox_node_names[tostring(cfg.node)]
    })
  }

  proxmox_nodes = {
    (var.node_name_0) = var.node_0_ip
    (var.node_name_1) = var.node_1_ip
    (var.node_name_2) = var.node_2_ip
  }

  expected_workspace = var.environment == "prod" ? "default" : var.environment
}

# ─────────────────────────────────────────────
# Виртуальные машины
# ─────────────────────────────────────────────

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.vms

  name      = each.value.name
  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  clone {
    vm_id = var.template_ids[tostring(each.value.node)]
    full  = true
  }

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = each.value.disk
    discard      = "on"
  }

  dynamic "disk" {
    for_each = each.value.data_disk != null ? [each.value.data_disk] : []
    content {
      datastore_id = "local-lvm"
      interface    = "scsi1"
      size         = disk.value
      discard      = "on"
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = lookup(var.static_ips, each.key, null) != null ? "${var.static_ips[each.key]}/24" : "dhcp"
        gateway = lookup(var.static_ips, each.key, null) != null ? var.gateway : null
      }
    }
    user_account {
      username = "ansible"
      keys     = split("\n", trimspace(file("./ssh-keys")))
      password = var.vm_password
    }
  }

  agent {
    enabled = true
  }

  lifecycle {
    # Не даёт случайно применить dev-параметры к production state и наоборот.
    precondition {
      condition     = terraform.workspace == local.expected_workspace
      error_message = "Окружение '${var.environment}' нужно применять в workspace '${local.expected_workspace}', выбран '${terraform.workspace}'."
    }

    precondition {
      condition     = alltrue([for key in keys(var.static_ips) : contains(keys(var.vms), key)])
      error_message = "Все ключи static_ips должны соответствовать VM из vms."
    }
  }
}

# ─────────────────────────────────────────────
# Генерируемый Ansible inventory
# ─────────────────────────────────────────────

locals {
  resolved_vms = [
    for key, cfg in local.vms : {
      name = proxmox_virtual_environment_vm.vm[key].name
      ip   = proxmox_virtual_environment_vm.vm[key].ipv4_addresses[1][0]
      role = cfg.role
    }
  ]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl", {
    vms           = local.resolved_vms
    proxmox_nodes = local.proxmox_nodes
  })
  filename             = "../ansible/inventory/hosts.yml"
  file_permission      = "0640"
  directory_permission = "0755"
}
