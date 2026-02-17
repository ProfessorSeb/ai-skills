# Kubernetes Deployment

Deploy agents from Agent Registry to Kubernetes clusters.

## Prerequisites

- Agent Registry daemon running (`arctl version`)
- Published agent (`arctl agent publish myagent`)
- Kubernetes cluster (kind, minikube, EKS, GKE, etc.)
- Current kubeconfig context set to target cluster
- [kagent](https://kagent.dev/docs/kagent/getting-started/quickstart) installed (used for bootstrapping)

## Local kind/minikube Setup

For local clusters, Agent Registry (Docker Compose) needs to reach the cluster API via Docker networking.

### Load image to kind
```bash
kind load docker-image ghcr.io/myagent:latest --name agentregistry
```

### Update kubeconfig for Docker networking
Edit `~/.kube/config` — find cluster entry and update:

```yaml
- cluster:
    insecure-skip-tls-verify: true
    server: https://host.docker.internal:<PORT>
  name: kind-agentregistry
```

Replace `127.0.0.1` with `host.docker.internal`, replace `certificate-authority-data` with `insecure-skip-tls-verify: true`. Keep the original port.

## Deploy

Use the Agent Registry UI at http://localhost:12121:
1. Navigate to published agents
2. Select agent → Deploy → Kubernetes
3. Follow prompts

## Cleanup

1. Open Agent Registry UI → Deployed view
2. Find deployment → Click **Remove**
