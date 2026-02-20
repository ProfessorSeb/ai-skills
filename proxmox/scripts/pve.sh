#!/usr/bin/env bash
# pve.sh — Proxmox VE API wrapper
# Usage: pve.sh <command> [args...]
# Reads PVE_HOST, PVE_USER, PVE_PASSWORD from env or ~/.config/proxmox/credentials
set -euo pipefail

CRED_FILE="${HOME}/.config/proxmox/credentials"

# Load credentials
if [[ -z "${PVE_HOST:-}" ]] && [[ -f "$CRED_FILE" ]]; then
  source "$CRED_FILE"
fi

: "${PVE_HOST:?Set PVE_HOST or create $CRED_FILE}"
: "${PVE_USER:?Set PVE_USER (e.g. root@pam)}"
: "${PVE_PASSWORD:?Set PVE_PASSWORD}"

BASE="https://${PVE_HOST}:8006/api2/json"
CURL="curl -sk --connect-timeout 10"

# Auth — get ticket + CSRF token
auth_response=$($CURL "${BASE}/access/ticket" \
  -d "username=${PVE_USER}&password=${PVE_PASSWORD}" 2>/dev/null)

TICKET=$(echo "$auth_response" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['ticket'])" 2>/dev/null)
CSRF=$(echo "$auth_response" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['CSRFPreventionToken'])" 2>/dev/null)

if [[ -z "$TICKET" ]]; then
  echo "ERROR: Authentication failed" >&2
  exit 1
fi

COOKIE="PVEAuthCookie=${TICKET}"

api_get() {
  $CURL -b "$COOKIE" "${BASE}${1}"
}

api_post() {
  local path="$1"; shift
  $CURL -b "$COOKIE" -H "CSRFPreventionToken: ${CSRF}" -X POST "${BASE}${path}" "$@"
}

api_put() {
  local path="$1"; shift
  $CURL -b "$COOKIE" -H "CSRFPreventionToken: ${CSRF}" -X PUT "${BASE}${path}" "$@"
}

api_delete() {
  $CURL -b "$COOKIE" -H "CSRFPreventionToken: ${CSRF}" -X DELETE "${BASE}${1}"
}

# Auto-detect node name
get_node() {
  if [[ -n "${PVE_NODE:-}" ]]; then
    echo "$PVE_NODE"
  else
    api_get "/nodes" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['node'])" 2>/dev/null
  fi
}

NODE=$(get_node)

# Pretty-print JSON helper
pp() { python3 -m json.tool 2>/dev/null || cat; }

cmd="${1:-help}"; shift 2>/dev/null || true

case "$cmd" in
  # === Cluster / Node ===
  version)        api_get "/version" | pp ;;
  status)         api_get "/nodes/${NODE}/status" | pp ;;
  nodes)          api_get "/nodes" | pp ;;
  cluster-status) api_get "/cluster/status" | pp ;;
  resources)      api_get "/cluster/resources" | pp ;;

  # === VMs (QEMU) ===
  vms)            api_get "/nodes/${NODE}/qemu" | pp ;;
  vm-status)      api_get "/nodes/${NODE}/qemu/${1}/status/current" | pp ;;
  vm-config)      api_get "/nodes/${NODE}/qemu/${1}/config" | pp ;;
  vm-start)       api_post "/nodes/${NODE}/qemu/${1}/status/start" | pp ;;
  vm-stop)        api_post "/nodes/${NODE}/qemu/${1}/status/stop" | pp ;;
  vm-shutdown)    api_post "/nodes/${NODE}/qemu/${1}/status/shutdown" | pp ;;
  vm-reboot)      api_post "/nodes/${NODE}/qemu/${1}/status/reboot" | pp ;;
  vm-reset)       api_post "/nodes/${NODE}/qemu/${1}/status/reset" | pp ;;
  vm-suspend)     api_post "/nodes/${NODE}/qemu/${1}/status/suspend" | pp ;;
  vm-resume)      api_post "/nodes/${NODE}/qemu/${1}/status/resume" | pp ;;
  vm-snapshots)   api_get "/nodes/${NODE}/qemu/${1}/snapshot" | pp ;;
  vm-snapshot)    api_post "/nodes/${NODE}/qemu/${1}/snapshot" -d "snapname=${2:-snap-$(date +%s)}" | pp ;;
  vm-clone)       api_post "/nodes/${NODE}/qemu/${1}/clone" -d "newid=${2}&name=${3:-clone-${1}}" | pp ;;
  vm-delete)      api_delete "/nodes/${NODE}/qemu/${1}" | pp ;;
  vm-resize)      api_put "/nodes/${NODE}/qemu/${1}/resize" -d "disk=${2}&size=${3}" | pp ;;
  vm-rrd)         api_get "/nodes/${NODE}/qemu/${1}/rrddata?timeframe=${2:-hour}" | pp ;;

  # === Containers (LXC) ===
  lxc)            api_get "/nodes/${NODE}/lxc" | pp ;;
  lxc-status)     api_get "/nodes/${NODE}/lxc/${1}/status/current" | pp ;;
  lxc-config)     api_get "/nodes/${NODE}/lxc/${1}/config" | pp ;;
  lxc-start)      api_post "/nodes/${NODE}/lxc/${1}/status/start" | pp ;;
  lxc-stop)       api_post "/nodes/${NODE}/lxc/${1}/status/stop" | pp ;;
  lxc-shutdown)   api_post "/nodes/${NODE}/lxc/${1}/status/shutdown" | pp ;;
  lxc-reboot)     api_post "/nodes/${NODE}/lxc/${1}/status/reboot" | pp ;;

  # === Storage ===
  storage)        api_get "/nodes/${NODE}/storage" | pp ;;
  storage-content) api_get "/nodes/${NODE}/storage/${1}/content" | pp ;;
  storage-status) api_get "/nodes/${NODE}/storage/${1}/status" | pp ;;

  # === Network ===
  network)        api_get "/nodes/${NODE}/network" | pp ;;

  # === Tasks ===
  tasks)          api_get "/nodes/${NODE}/tasks?limit=${1:-10}" | pp ;;
  task-status)    api_get "/nodes/${NODE}/tasks/${1}/status" | pp ;;
  task-log)       api_get "/nodes/${NODE}/tasks/${1}/log" | pp ;;

  # === Backups ===
  backup-vm)      api_post "/nodes/${NODE}/qemu/${1}/snapshot" -d "snapname=backup-$(date +%s)" | pp ;;

  # === ISO / Templates ===
  isos)           api_get "/nodes/${NODE}/storage/${1:-local}/content?content=iso" | pp ;;
  templates)      api_get "/nodes/${NODE}/storage/${1:-local}/content?content=vztmpl" | pp ;;

  # === Raw API ===
  get)            api_get "$1" | pp ;;
  post)           shift; api_post "$@" | pp ;;
  put)            shift; api_put "$@" | pp ;;
  delete)         api_delete "$1" | pp ;;

  help|*)
    cat <<'USAGE'
pve.sh — Proxmox VE CLI wrapper

Cluster:    version | status | nodes | cluster-status | resources
VMs:        vms | vm-status <id> | vm-config <id>
            vm-start <id> | vm-stop <id> | vm-shutdown <id> | vm-reboot <id>
            vm-suspend <id> | vm-resume <id> | vm-reset <id>
            vm-snapshots <id> | vm-snapshot <id> [name]
            vm-clone <id> <newid> [name] | vm-delete <id>
            vm-resize <id> <disk> <size> | vm-rrd <id> [timeframe]
LXC:        lxc | lxc-status <id> | lxc-config <id>
            lxc-start <id> | lxc-stop <id> | lxc-shutdown <id> | lxc-reboot <id>
Storage:    storage | storage-content <name> | storage-status <name>
Network:    network
Tasks:      tasks [limit] | task-status <upid> | task-log <upid>
ISOs:       isos [storage] | templates [storage]
Raw API:    get <path> | post <path> [curl-args] | put <path> [curl-args] | delete <path>

Environment: PVE_HOST, PVE_USER, PVE_PASSWORD, PVE_NODE (optional)
Credentials file: ~/.config/proxmox/credentials
USAGE
    ;;
esac
