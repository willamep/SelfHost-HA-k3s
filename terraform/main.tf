# ─────────────────────────────────────────────
# Описание парка VM
#
# vm_id схема:  <нода><роль><номер>   →  N11 server, N12 agent, 110/113 infra
#   1xx → Proxmox #0 (Nik-Node-0, 16 GB)
#   2xx → Proxmox #1 (Nik-Node-1, 16 GB)
#   3xx → Proxmox #2 (Nik-Node-2, 32 GB)
#
# Шаблон (var.template_id) лежит на ноде 2 → cross-node clone на ноды 0/1.
# ─────────────────────────────────────────────

locals {
  vms = {
    # ── Proxmox #0 (16 GB) ──────────────────────
    "wireguard" = {
      name   = "WireGuard"
      vm_id  = 110
      node   = var.node_name_0
      cores  = 1
      memory = 750
      disk   = 8
      role   = "wireguard"
    }
    "k3s-server-1" = {
      name   = "k3s-server-1" # init-нода кластера (--cluster-init)
      vm_id  = 111
      node   = var.node_name_0
      cores  = 2
      memory = 2048
      disk   = 50
      role   = "servers"
    }
    "k3s-agent-1" = {
      name   = "k3s-agent-1"
      vm_id  = 112
      node   = var.node_name_0
      cores  = 6
      memory = 9216
      disk   = 200
      role   = "agents"
    }
    "nfs-server" = {
      name   = "nfs-server"
      vm_id  = 113
      node   = var.node_name_0
      cores  = 1
      memory = 1024
      disk   = 50
      role   = "nfs-server"
    }

    # ── Proxmox #1 (16 GB) ──────────────────────
    # В ноде крайне маленький ssd 128 Gb
    # Из-за этого так же не делался Seph
    "k3s-server-2" = {
      name   = "k3s-server-2"
      vm_id  = 211
      node   = var.node_name_1
      cores  = 2
      memory = 2048
      disk   = 10
      role   = "servers"
    }
    "k3s-agent-2" = {
      name   = "k3s-agent-2"
      vm_id  = 212
      node   = var.node_name_1
      cores  = 6
      memory = 10240
      disk   = 35
      role   = "agents"
    }

    # ── Proxmox #2 (32 GB) ──────────────────────
    "k3s-server-3" = {
      name   = "k3s-server-3"
      vm_id  = 311
      node   = var.node_name_2
      cores  = 2
      memory = 8192
      disk   = 50
      role   = "servers"
    }
    "k3s-agent-3" = {
      name   = "k3s-agent-3"
      vm_id  = 312
      node   = var.node_name_2
      cores  = 6
      memory = 20480
      disk   = 200
      role   = "agents"
    }
  }

  # Физические Proxmox-ноды (для ansible-инвентаря и outputs)
  proxmox_nodes = {
    (var.node_name_0) = var.node_0_ip
    (var.node_name_1) = var.node_1_ip
    (var.node_name_2) = var.node_2_ip
  }

  # Статические IP (сеть 192.168.3.0/24). Ноды вне этой map — на DHCP.
  static_ips = {
    "k3s-server-1" = "192.168.3.201"
    "k3s-server-2" = "192.168.3.202"
    "k3s-server-3" = "192.168.3.203"
    "wireguard"    = "192.168.3.204"
    "nfs-server"   = "192.168.3.205"
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
