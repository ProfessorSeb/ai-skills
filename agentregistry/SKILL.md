---
name: agentregistry
description: "Agent Registry (aregistry.ai) skill for managing AI artifact catalogs with the `arctl` CLI. Use when:
(1) Installing or setting up Agent Registry and the arctl CLI
(2) Creating agents from templates (Google ADK, etc.)
(3) Building, publishing, and deploying agent Docker images
(4) Creating MCP servers, adding tools, building and publishing MCP server images
(5) Creating and publishing skills as Docker images
(6) Deploying agents or MCP servers locally or to Kubernetes (kind, minikube, cloud)
(7) Adding MCP servers to agents for tool access
(8) Configuring IDE integrations (Claude Desktop, Cursor, VS Code) via Agent Gateway
(9) Listing, searching, or discovering AI artifacts in the registry
(10) Managing artifact lifecycle: publish, unpublish, versioning, governance"
---

# Agent Registry

Open source AI artifact catalog. Build, package, publish, discover, and govern Docker images for agents, MCP servers, and skills across registries.

- **Docs:** https://aregistry.ai/docs/
- **GitHub:** https://github.com/agentregistry-dev/agentregistry
- **UI:** http://localhost:12121 (when daemon running)
- **CLI:** `arctl`

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/agentregistry-dev/agentregistry/main/scripts/get-arctl | bash
```

Start daemon (auto-starts on first CLI call):
```bash
arctl version
```

**Prerequisites:** Docker Desktop with Docker Compose v2+.

## Core Concepts

- **Agents** — AI agents packaged as Docker images (ADK/Python, etc.)
- **MCP Servers** — Model Context Protocol servers exposing tools/resources
- **Skills** — Reusable agent capabilities packaged as Docker images
- **Agent Gateway** — Reverse proxy providing single MCP endpoint for all deployed servers
- **Registry** — Centralized catalog at localhost:12121 for discovery/governance

## Agents

### Create
```bash
arctl agent init adk python myagent
```
Creates scaffold: `agent.yaml`, `Dockerfile`, `docker-compose.yaml`, `pyproject.toml`, agent dir with `agent.py`.

Edit `agent.yaml` to set image registry/tag (default: `ghcr.io/myagent:latest`).

### Run locally
```bash
export GOOGLE_API_KEY=<key>   # or relevant provider key
arctl agent run myagent
```

### Build
```bash
arctl agent build myagent              # local only
arctl agent build myagent --push       # build + push to registry
arctl agent build myagent --platform linux/amd64 --push
```

### Publish to registry
```bash
arctl agent publish myagent
arctl agent list
```

### Unpublish
```bash
arctl agent unpublish myagent
```

### Add MCP servers to agent
```bash
arctl agent add-mcp --project-dir myagent
```
Interactive wizard: select registry MCP server, set env vars (`MCP_TRANSPORT_MODE=http`, `HOST=0.0.0.0`), name it. Updates `agent.yaml` with `mcpServers` block.

### Deploy
- **Local:** Deploy via UI at http://localhost:12121 → Deployed view
- **Kubernetes:** See [references/kubernetes-deploy.md](references/kubernetes-deploy.md)

## MCP Servers

### Create
```bash
arctl mcp init python my-mcp-server
```
Creates scaffold with echo tool, Dockerfile, src/tools/.

### Add tools
```bash
arctl mcp add-tool add_number --project-dir my-mcp-server
```
Edit generated `src/tools/add_number.py` with tool logic.

### Build
```bash
arctl mcp build my-mcp-server
```

### Run locally
```bash
arctl mcp run my-mcp-server
```
Outputs MCP Server URL (e.g., `http://localhost:57196/mcp`). Test with MCP inspector:
```bash
npx modelcontextprotocol/inspector#0.18.0
```

### Publish
```bash
arctl mcp publish my-mcp-server --docker-url docker.io/user
arctl mcp list
```
Add `--push` to also push to container registry.

### Unpublish
```bash
arctl mcp unpublish user/my-mcp-server --version 0.1.0
```

## Skills

### Create
```bash
arctl skill init myskill
```
Creates scaffold: `SKILL.md`, `Dockerfile`, `scripts/`, `references/`, `assets/`, `LICENSE.txt`.

### Publish
```bash
arctl skill publish myskill --docker-url docker.io/user
arctl skill list
```
Add `--push` to push to container registry.

### Unpublish
```bash
arctl skill unpublish hello-world-template --version latest
```

## IDE Configuration

Generate config for AI IDEs to use Agent Gateway:
```bash
arctl configure claude-desktop
arctl configure cursor
arctl configure vscode
```

## Common Workflows

### Full agent workflow
1. `arctl agent init adk python myagent`
2. Customize agent code + `agent.yaml`
3. `arctl agent build myagent`
4. `arctl agent run myagent` (test locally)
5. `arctl agent publish myagent`
6. Deploy via UI or K8s

### Full MCP server workflow
1. `arctl mcp init python my-server`
2. `arctl mcp add-tool mytool --project-dir my-server`
3. Implement tool logic in `src/tools/mytool.py`
4. `arctl mcp build my-server`
5. `arctl mcp run my-server` (test with inspector)
6. `arctl mcp publish my-server --docker-url <registry>`

### Compose agent + MCP
1. Publish MCP server to registry
2. `arctl agent add-mcp --project-dir myagent` (select from registry)
3. Rebuild + run agent → agent now has MCP tools
