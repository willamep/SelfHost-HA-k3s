environment = "dev"

vms = {
  # Proxmox #0
  "k3s-server-1" = {
    name   = "k3s-server-dev-1"
    vm_id  = 900
    node   = 0
    cores  = 2
    memory = 1536
    disk   = 30
    role   = "servers"
  }
  "k3s-agent-1" = {
    name   = "k3s-agent-dev-1"
    vm_id  = 901
    node   = 0
    cores  = 2
    memory = 2560
    disk   = 30
    role   = "agents"
  }

  # Proxmox #1
  "k3s-server-2" = {
    name   = "k3s-server-dev-2"
    vm_id  = 902
    node   = 1
    cores  = 2
    memory = 1536
    disk   = 30
    role   = "servers"
  }
  "k3s-agent-2" = {
    name   = "k3s-agent-dev-2"
    vm_id  = 903
    node   = 1
    cores  = 2
    memory = 2560
    disk   = 30
    role   = "agents"
  }

  # Proxmox #2
  "k3s-server-3" = {
    name   = "k3s-server-dev-3"
    vm_id  = 904
    node   = 2
    cores  = 2
    memory = 2560
    disk   = 30
    role   = "servers"
  }
  "k3s-agent-3" = {
    name   = "k3s-agent-dev-3"
    vm_id  = 905
    node   = 2
    cores  = 2
    memory = 2560
    disk   = 30
    role   = "agents"
  }
  "nfs-server" = {
    name   = "nfs-server-dev-1"
    vm_id  = 906
    node   = 2
    cores  = 1
    memory = 1024
    disk   = 30
    role   = "nfs_server"
  }
  "victoriametrics" = {
    name      = "victoriametrics-dev-1"
    vm_id     = 907
    node      = 2
    cores     = 2
    memory    = 2048
    disk      = 10
    data_disk = 20
    role      = "victoriametrics"
  }
}

static_ips = {
  "k3s-server-1"    = "192.168.3.201"
  "k3s-server-2"    = "192.168.3.202"
  "k3s-server-3"    = "192.168.3.203"
  "nfs-server"      = "192.168.3.205"
  "victoriametrics" = "192.168.3.207"
}
