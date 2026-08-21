# ───────────────────────────────────────────────────────────────────────
# Описание парка VM:
#
# vm_id схема:  <нода><10-99>
#   1xx → Proxmox #0 (Nik-Node-0, 16 GB RAM):
#   2xx → Proxmox #1 (Nik-Node-1, 16 GB RAM):
#   3xx → Proxmox #2 (Nik-Node-2, 32 GB RAM):
#
# Шаблон (var.template_id) лежит на ноде 2 → cross-node clone на ноды 0/1.
#
# В ВМ nextcloud вручную пробрасывается физический RAID с
# пользовательскими файлами — осознанный дрейф вне terraform.
# Внутри гостя диск монтируется по UUID Ansible-ролью nextcloud_vm.
# ───────────────────────────────────────────────────────────────────────

locals {
  vms = {
    # ── Proxmox #0 ──────────────────────────────
    "k3s-server-1" = {
      name   = "k3s-server-dev-1"
      vm_id  = 900
      node   = var.node_name_0
      cores  = 2
      memory = 1536
      disk   = 30
      role   = "servers"
    }

    "k3s-agent-1" = {
      name   = "k3s-agent-dev-1"
      vm_id  = 901
      node   = var.node_name_0
      cores  = 2
      memory = 2560
      disk   = 30
      role   = "agents"
    }

    # ── Proxmox #1 ──────────────────────────────
    "k3s-server-2" = {
      name   = "k3s-server-dev-2"
      vm_id  = 902
      node   = var.node_name_1
      cores  = 2
      memory = 1536
      disk   = 30
      role   = "servers"
    }

    "k3s-agent-2" = {
      name   = "k3s-agent-dev-2"
      vm_id  = 903
      node   = var.node_name_1
      cores  = 2
      memory = 2560
      disk   = 30
      role   = "agents"
    }

    # ── Proxmox #2 ──────────────────────────────
    "k3s-server-3" = {
      name   = "k3s-server-dev-3"
      vm_id  = 904
      node   = var.node_name_2
      cores  = 2
      memory = 2560
      disk   = 30
      role   = "servers"
    }

    "k3s-agent-3" = {
      name   = "k3s-agent-dev-3"
      vm_id  = 905
      node   = var.node_name_2
      cores  = 2
      memory = 2560
      disk   = 30
      role   = "agents"
    }

    "nfs-server" = {
      name   = "nfs-server-dev-1"
      vm_id  = 906
      node   = var.node_name_2
      cores  = 1
      memory = 1024
      disk   = 30
      role   = "nfs_server"
    }

    "victoriametrics" = {
      name      = "victoriametrics-dev-1"
      vm_id     = 907
      node      = var.node_name_2
      cores     = 2
      memory    = 2048
      disk      = 10
      data_disk = 20
      role      = "victoriametrics"
    }
  }

  proxmox_nodes = {
    (var.node_name_0) = var.node_0_ip
    (var.node_name_1) = var.node_1_ip
    (var.node_name_2) = var.node_2_ip
  }

  static_ips = {
    "k3s-server-1"    = "192.168.3.201"
    "k3s-server-2"    = "192.168.3.202"
    "k3s-server-3"    = "192.168.3.203"
    "nfs-server"      = "192.168.3.205"
    "victoriametrics" = "192.168.3.207"
  }
}

# ─────────────────────────────────────────────
# Виртуальные машины
# ─────────────────────────────────────────────

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.vms

  name      = each.value.name
  node_name = each.value.node
  vm_id     = each.value.vm_id

  clone {
    vm_id = var.template_id
    full  = true
    # источник клона. На ноде 2 шаблон локальный → оставляем пустым;
    # для нод 0/1 указываем ноду 2 (cross-node clone). Атрибут ForceNew.
    node_name = each.value.node == var.node_name_2 ? null : var.node_name_2
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

  # Диск данных (scsi1) — только у ВМ, где задан data_disk. Ресурс общий на все
  # ВМ через for_each; обычный второй disk-блок прицепился бы ко всем — dynamic
  # включает его точечно (у остальных поля нет → пустой итератор → диска нет).
  dynamic "disk" {
    for_each = lookup(each.value, "data_disk", null) != null ? [each.value.data_disk] : []
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
        address = lookup(local.static_ips, each.key, null) != null ? "${local.static_ips[each.key]}/24" : "dhcp"
        gateway = lookup(local.static_ips, each.key, null) != null ? var.gateway : null
      }
    }
    user_account {
      username = "ansible"
      keys     = [file("./ssh-keys")]
      password = var.vm_password
    }
  }

  agent {
    enabled = true
  }
}

# ─────────────────────────────────────────────
# Ansible inventory
# ─────────────────────────────────────────────

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl", {
    vms = [
      for key, cfg in local.vms : {
        name = proxmox_virtual_environment_vm.vm[key].name
        ip   = proxmox_virtual_environment_vm.vm[key].ipv4_addresses[1][0]
        role = cfg.role
      }
    ]
    proxmox_nodes = local.proxmox_nodes
  })
  filename             = "../ansible/inventory/hosts.yml"
  file_permission      = "0640"
  directory_permission = "0755"
}
