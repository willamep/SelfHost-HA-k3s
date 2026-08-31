# homelab-k3s

Инфраструктура домашней лаборатории как код: HA-кластер k3s на Proxmox,
хранилище, VPN и self-hosted сервисы. Terraform создаёт ВМ и генерирует
inventory, Ansible доводит их до целевого состояние и деплоит ArgoCD bootstrap.

## Архитектура

3 физические ноды Proxmox. k3s состоит из трёх совмещённых server/worker-нод
и отдельного агента для CI:

| Нода | ВМ |
|---|---|
| Nik-Node-0 (16 ГБ) | nextcloud (docker compose + проброшенный RAID), k3s-server-1 |
| Nik-Node-1 (16 ГБ) | wireguard, k3s-server-2 |
| Nik-Node-2 (32 ГБ) | nfs-server (PVC кластера), VictoriaMetrics, k3s-server-3, k3s-ci-agent-1 |

- **k3s HA**: 3 server-ноды с embedded etcd также запускают обычные workload;
  kube-vip даёт VIP API и LB-адрес для traefik.
- **CI**: отдельный k3s-agent помечен `workload=ci` и защищён taint
  `workload=ci:NoSchedule`; GitLab Runner должен использовать соответствующие
  `nodeSelector` и `tolerations`.
- **Вход**: traefik — единая точка входа для сервисов, внешний ip от kube-vip.
- **Nextcloud**: выделенная ВМ с Docker Compose; данные пользователей находятся на проброшшеном raid1.
- **Хранилище**: nfs-server отдаёт динамические PV (nfs-subdir-provisioner)
  для мониторинга; пользовательские файлы Nextcloud — на физическом RAID,
  проброшенном в её ВМ.
- **Мониторинг**: kube-prometheus-stack; хосты вне кластера — node_exporter
  и pve_exporter через `monitoring_external_jobs`.
- **Доступ извне**: WireGuard.

## Структура

```
terraform/   ВМ Proxmox (bpg/proxmox), среда для dev/prod, генерация ansible-инвентаря
ansible/     роли: k3s_servers, k3s_agents, nfs_server, nfs-provisioner, 
             docker, nextcloud_vm, node_exporter, pve_exporter, wireguard
kubernetes/  Ресурсы для ArgoCD
```

## Применение

```bash
terraform -chdir=terraform apply
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook ansible/main.yml
```

Конвенция: шаблоны без хардкода — все значения в `ansible/group_vars/all/`
(секреты — ansible-vault в `vault.yml`).

