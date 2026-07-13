# homelab-k3s

Инфраструктура домашней лаборатории как код: HA-кластер k3s на Proxmox,
хранилище, VPN и self-hosted сервисы. Terraform создаёт ВМ и генерирует
inventory, Ansible доводит их до целевого состояния.

## Архитектура

3 физические ноды Proxmox, 9 ВМ:

| Нода | ВМ |
|---|---|
| Nik-Node-0 (16 ГБ) | nextcloud (docker compose + проброшенный RAID), k3s-server-1, k3s-agent-1 |
| Nik-Node-1 (16 ГБ) | wireguard, k3s-server-2, k3s-agent-2 |
| Nik-Node-2 (32 ГБ) | nfs-server (PVC кластера), k3s-server-3, k3s-agent-3 |

- **k3s HA**: 3 сервера (embedded etcd) + 3 агента; kube-vip даёт VIP API
  и LB-адрес для traefik.
- **Вход**: traefik (встроенный в k3s) — единая точка входа для всего,
  включая сервисы вне кластера; TLS — cert-manager (Let's Encrypt http-01).
- **Nextcloud**: выделенная ВМ с Docker Compose; traefik кластера проксирует
  на неё через Service без селектора + EndpointSlice.
  Почему не в кластере — [ADR-0001](docs/adr/0001-migrate-nextcloud-to-dedicated-vm.md).
- **Хранилище**: nfs-server отдаёт динамические PV (nfs-subdir-provisioner)
  для мониторинга; пользовательские файлы Nextcloud — на физическом RAID,
  проброшенном в её ВМ.
- **Мониторинг**: kube-prometheus-stack; хосты вне кластера — node_exporter
  и pve_exporter через `monitoring_external_jobs`.
- **Доступ извне**: WireGuard.

## Структура

```
terraform/   ВМ Proxmox (bpg/proxmox), генерация ansible-инвентаря
ansible/     роли: k3s_servers, k3s_agents, nfs_server, nfs-provisioner,
             traefik, cert_manager, monitoring, docker, nextcloud_vm,
             nextcloud_ingress, node_exporter, pve_exporter, wireguard
docs/adr/    журнал архитектурных решений
```

## Применение

```bash
terraform -chdir=terraform apply
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook ansible/homelab-k3s.yml
```

Конвенция: шаблоны без хардкода — все значения в `ansible/group_vars/all/`
(секреты — ansible-vault в `vault.yml`).

## Решения

- [ADR-0001: Nextcloud из k3s в выделенную ВМ](docs/adr/0001-migrate-nextcloud-to-dedicated-vm.md)
