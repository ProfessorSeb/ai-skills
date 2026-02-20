---
name: proxmox
description: |
  Manage Proxmox VE hypervisor: VMs, LXC containers, storage, snapshots, backups, and node status.
  Use when:
  (1) Listing, starting, stopping, or rebooting VMs or containers
  (2) Checking node/cluster status, CPU, memory, disk usage
  (3) Creating snapshots, clones, or managing VM lifecycle
  (4) Viewing storage, ISOs, templates, network config
  (5) Querying task history or monitoring operations
  (6) Any Proxmox/PVE management task
---

# Proxmox VE Skill

Manage a Proxmox VE hypervisor via the REST API using the bundled `pve.sh` wrapper script.

## Setup

Credentials file at `~/.config/proxmox/credentials`:
```
PVE_HOST="<ip-or-hostname>"
PVE_USER="root@pam"
PVE_PASSWORD="<password>"
```

Alternatively set `PVE_HOST`, `PVE_USER`, `PVE_PASSWORD` as env vars. Optional: `PVE_NODE` to skip auto-detect.

**Never read or print the credentials file contents.** Reference by path only.

## Usage

Run commands via the wrapper script:

```bash
scripts/pve.sh <command> [args...]
```

All paths in this skill are relative to the skill directory.

## Commands

### Cluster / Node
| Command | Description |
|---------|-------------|
| `version` | PVE version |
| `status` | Node status (CPU, memory, uptime, load) |
| `nodes` | List all nodes |
| `cluster-status` | Cluster health |
| `resources` | All cluster resources (VMs, storage, nodes) |

### VMs (QEMU)
| Command | Description |
|---------|-------------|
| `vms` | List all VMs |
| `vm-status <id>` | VM status |
| `vm-config <id>` | VM configuration |
| `vm-start <id>` | Start VM |
| `vm-stop <id>` | Force stop VM |
| `vm-shutdown <id>` | Graceful shutdown |
| `vm-reboot <id>` | Reboot VM |
| `vm-suspend <id>` | Suspend VM |
| `vm-resume <id>` | Resume VM |
| `vm-snapshots <id>` | List snapshots |
| `vm-snapshot <id> [name]` | Create snapshot |
| `vm-clone <id> <newid> [name]` | Clone VM |
| `vm-delete <id>` | Delete VM |
| `vm-resize <id> <disk> <size>` | Resize disk (e.g. `scsi0 +10G`) |
| `vm-rrd <id> [timeframe]` | Performance data (hour/day/week/month) |

### Containers (LXC)
| Command | Description |
|---------|-------------|
| `lxc` | List all containers |
| `lxc-status <id>` | Container status |
| `lxc-config <id>` | Container config |
| `lxc-start <id>` | Start container |
| `lxc-stop <id>` | Force stop |
| `lxc-shutdown <id>` | Graceful shutdown |
| `lxc-reboot <id>` | Reboot |

### Storage
| Command | Description |
|---------|-------------|
| `storage` | List storage pools |
| `storage-content <name>` | List content in storage |
| `storage-status <name>` | Storage usage stats |
| `isos [storage]` | List ISO images |
| `templates [storage]` | List container templates |

### Network / Tasks
| Command | Description |
|---------|-------------|
| `network` | Network interfaces |
| `tasks [limit]` | Recent tasks |
| `task-status <upid>` | Task status |
| `task-log <upid>` | Task log |

### Raw API
For any endpoint not covered above:

```bash
scripts/pve.sh get /nodes/pro/qemu/100/agent/info
scripts/pve.sh post /nodes/pro/qemu/100/status/start
```

## Safety

- `vm-stop` and `vm-delete` are destructive — confirm with the user before running
- `vm-shutdown` is preferred over `vm-stop` (graceful vs force)
- Always list VMs first to confirm IDs before acting on them
- Snapshot before risky operations

## Common Patterns

**Quick overview:**
```bash
scripts/pve.sh nodes       # node health
scripts/pve.sh vms         # all VMs
scripts/pve.sh lxc         # all containers
scripts/pve.sh storage     # storage pools
```

**VM lifecycle:**
```bash
scripts/pve.sh vm-snapshot 104           # snapshot before changes
scripts/pve.sh vm-shutdown 104           # graceful stop
scripts/pve.sh vm-start 104              # start
scripts/pve.sh vm-status 104             # verify
```

**Parse VM list for readable output:**
```bash
scripts/pve.sh vms | python3 -c "
import sys,json
for vm in sorted(json.load(sys.stdin)['data'], key=lambda x: x['vmid']):
    print(f\"{vm['vmid']:>4}  {vm['name']:<20} {vm['status']:<10} CPU:{vm.get('cpus',0)} MEM:{vm.get('maxmem',0)//1024//1024//1024}G\")
"
```

## API Reference

For endpoints not covered by the wrapper, see [references/api.md](references/api.md).
