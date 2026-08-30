environment = "prod"

vms = {
  # Proxmox #0 (16 GB)
  "nextcloud" = {
    name   = "nextcloud-1"
    vm_id  = 110
    node   = 0
    cores  = 2
    memory = 2560
    disk   = 40
    role   = "nextcloud"
  }
  "k3s-server-1" = {
    name   = "k3s-server-1"
    vm_id  = 111
    node   = 0
    cores  = 2
    memory = 2048
    disk   = 50
    role   = "servers"
  }
  "k3s-agent-1" = {
    name   = "k3s-agent-1"
    vm_id  = 112
    node   = 0
    cores  = 6
    memory = 9216
    disk   = 200
    role   = "agents"
  }

  # Proxmox #1 (16 GB, SSD 128 GB)
  "wireguard" = {
    name   = "wireguard-1"
    vm_id  = 210
    node   = 1
    cores  = 1
    memory = 750
    disk   = 8
    role   = "wireguard"
  }
  "k3s-server-2" = {
    name   = "k3s-server-2"
    vm_id  = 211
    node   = 1
    cores  = 2
    memory = 2048
    disk   = 10
    role   = "servers"
  }
  "k3s-agent-2" = {
    name   = "k3s-agent-2"
    vm_id  = 212
    node   = 1
    cores  = 6
    memory = 10240
    disk   = 35
    role   = "agents"
  }

  # Proxmox #2 (32 GB)
  "nfs-server" = {
    name   = "nfs-server-1"
    vm_id  = 310
    node   = 2
    cores  = 1
    memory = 1024
    disk   = 50
    role   = "nfs_server"
  }
  "k3s-server-3" = {
    name   = "k3s-server-3"
    vm_id  = 311
    node   = 2
    cores  = 2
    memory = 3072
    disk   = 50
    role   = "servers"
  }
  "k3s-agent-3" = {
    name   = "k3s-agent-3"
    vm_id  = 312
    node   = 2
    cores  = 6
    memory = 20480
    disk   = 200
    role   = "agents"
  }
  "victoriametrics" = {
    name      = "victoriametrics-1"
    vm_id     = 313
    node      = 2
    cores     = 2
    memory    = 4096
    disk      = 10
    data_disk = 20
    role      = "victoriametrics"
  }
}

static_ips = {
  "k3s-server-1"    = "192.168.3.201"
  "k3s-server-2"    = "192.168.3.202"
  "k3s-server-3"    = "192.168.3.203"
  "wireguard"       = "192.168.3.204"
  "nfs-server"      = "192.168.3.205"
  "nextcloud"       = "192.168.3.206"
  "victoriametrics" = "192.168.3.207"
}
