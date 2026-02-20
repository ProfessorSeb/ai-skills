# Proxmox VE API Reference

Base URL: `https://<host>:8006/api2/json`

## Authentication

POST `/access/ticket` with `username` + `password` → returns `ticket` (cookie) and `CSRFPreventionToken` (header for writes).

## Key Endpoints

### Nodes
- `GET /nodes` — list nodes
- `GET /nodes/{node}/status` — node status (CPU, memory, uptime, loadavg, kernel)
- `GET /nodes/{node}/network` — network interfaces
- `GET /nodes/{node}/tasks` — task list (`?limit=N`)
- `GET /nodes/{node}/tasks/{upid}/status` — task result
- `GET /nodes/{node}/tasks/{upid}/log` — task log

### QEMU VMs
- `GET /nodes/{node}/qemu` — list VMs
- `GET /nodes/{node}/qemu/{vmid}/status/current` — VM status
- `GET /nodes/{node}/qemu/{vmid}/config` — VM config
- `POST /nodes/{node}/qemu/{vmid}/status/start|stop|shutdown|reboot|suspend|resume|reset`
- `GET /nodes/{node}/qemu/{vmid}/snapshot` — list snapshots
- `POST /nodes/{node}/qemu/{vmid}/snapshot` — create snapshot (`snapname`)
- `DELETE /nodes/{node}/qemu/{vmid}/snapshot/{snapname}` — delete snapshot
- `POST /nodes/{node}/qemu/{vmid}/snapshot/{snapname}/rollback` — rollback
- `POST /nodes/{node}/qemu/{vmid}/clone` — clone (`newid`, `name`, `full`)
- `DELETE /nodes/{node}/qemu/{vmid}` — destroy VM
- `PUT /nodes/{node}/qemu/{vmid}/config` — update config
- `PUT /nodes/{node}/qemu/{vmid}/resize` — resize disk (`disk`, `size`)
- `GET /nodes/{node}/qemu/{vmid}/rrddata` — performance (`?timeframe=hour|day|week|month`)
- `POST /nodes/{node}/qemu/{vmid}/agent/{command}` — QEMU guest agent

### LXC Containers
- `GET /nodes/{node}/lxc` — list containers
- `GET /nodes/{node}/lxc/{vmid}/status/current` — status
- `GET /nodes/{node}/lxc/{vmid}/config` — config
- `POST /nodes/{node}/lxc/{vmid}/status/start|stop|shutdown|reboot`
- Same snapshot/clone/delete pattern as QEMU

### Storage
- `GET /nodes/{node}/storage` — list pools
- `GET /nodes/{node}/storage/{storage}/content` — list content (`?content=iso|vztmpl|backup|images`)
- `GET /nodes/{node}/storage/{storage}/status` — usage
- `POST /nodes/{node}/storage/{storage}/upload` — upload file

### Cluster
- `GET /cluster/status` — cluster health
- `GET /cluster/resources` — all resources (`?type=vm|storage|node`)
- `GET /cluster/tasks` — cluster-wide tasks
- `GET /cluster/backup` — backup schedules

### Access
- `GET /access/users` — list users
- `GET /access/roles` — list roles
- `GET /access/acl` — ACL list

## Response Format

All responses: `{"data": <result>}`. Write operations return a UPID (task ID) for async tracking.
