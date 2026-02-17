# AgentGateway MCP (Model Context Protocol)

Configure MCP servers and secure tool access through AgentGateway.

## Table of Contents
- [Overview](#overview)
- [Static MCP](#static-mcp)
- [Dynamic MCP](#dynamic-mcp)
- [MCP Tool Authorization](#mcp-tool-authorization)
- [Rate Limiting MCP](#rate-limiting-mcp)

---

## Overview

MCP (Model Context Protocol) allows AI agents to discover and call external tools. AgentGateway acts as a secure gateway for MCP traffic:

- **Tool Discovery** — Agents call `tools/list` to see available tools
- **Tool Execution** — Agents call `tools/call` to invoke tools
- **Authorization** — Control which tools can be called
- **Rate Limiting** — Prevent tool abuse

---

## Static MCP

Route to a single MCP server.

### MCP Backend
```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: github-mcp
  namespace: agentgateway-system
spec:
  mcp:
    target:
      host: github-mcp-server.mcp.svc.cluster.local
      port: 8080
```

### Gateway + Route
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: mcp-gateway
  namespace: agentgateway-system
spec:
  gatewayClassName: enterprise-agentgateway
  listeners:
  - name: http
    port: 8090
    protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mcp-routes
  namespace: agentgateway-system
spec:
  parentRefs:
  - name: mcp-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /mcp/github
    backendRefs:
    - group: agentgateway.dev
      kind: AgentgatewayBackend
      name: github-mcp
```

### Test MCP
```bash
# List tools
curl -X POST $MCP_GATEWAY/mcp/github \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'

# Call a tool
curl -X POST $MCP_GATEWAY/mcp/github \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"tools/call",
    "params":{
      "name":"get_repository",
      "arguments":{"owner":"solo-io","repo":"agentgateway"}
    },
    "id":2
  }'
```

---

## Dynamic MCP

Multiplex requests to different MCP servers based on path.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mcp-multiplex
spec:
  parentRefs:
  - name: mcp-gateway
  rules:
  # GitHub tools
  - matches:
    - path:
        type: PathPrefix
        value: /mcp/github
    backendRefs:
    - group: agentgateway.dev
      kind: AgentgatewayBackend
      name: github-mcp
  # Slack tools
  - matches:
    - path:
        type: PathPrefix
        value: /mcp/slack
    backendRefs:
    - group: agentgateway.dev
      kind: AgentgatewayBackend
      name: slack-mcp
  # Database tools
  - matches:
    - path:
        type: PathPrefix
        value: /mcp/postgres
    backendRefs:
    - group: agentgateway.dev
      kind: AgentgatewayBackend
      name: postgres-mcp
```

---

## MCP Tool Authorization

Control which tools AI agents can call using CEL expressions.

### Allow Read-Only Tools
```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: mcp-read-only
  namespace: agentgateway-system
spec:
  targetRefs:
  - kind: HTTPRoute
    name: mcp-routes
  backend:
    mcp:
      toolAuth:
        defaultAction: Deny  # Block by default
        rules:
        # Allow read operations
        - tools:
          - "get_*"
          - "list_*"
          - "search_*"
          - "read_*"
          action: Allow
        # Block write operations
        - tools:
          - "create_*"
          - "delete_*"
          - "update_*"
          - "write_*"
          action: Deny
          response:
            message: "🚫 Write operations require approval"
```

### Block Dangerous Tools with CEL
```yaml
backend:
  mcp:
    toolAuth:
      rules:
      - cel: |
          tool.name.contains('delete') ||
          tool.name.contains('reboot') ||
          tool.name.contains('shutdown') ||
          tool.name.contains('reset') ||
          tool.name.contains('wipe')
        action: Deny
        response:
          message: "🚫 Critical operation blocked - requires human approval"
```

### Parameter-Level Control
```yaml
backend:
  mcp:
    toolAuth:
      rules:
      # Block dangerous parameter combinations
      - cel: |
          tool.name == 'update_config' &&
          (tool.arguments['force'] == true ||
           tool.arguments['skipBackup'] == true)
        action: Deny
        response:
          message: "🚫 Dangerous parameters blocked"
```

### Role-Based Tool Access
```yaml
backend:
  mcp:
    toolAuth:
      rules:
      # Admin-only tools
      - cel: |
          claims.role == 'admin' &&
          tool.name.startsWith('admin_')
        action: Allow
      # Regular users - read only
      - cel: |
          claims.role == 'user' &&
          tool.name.startsWith('get_')
        action: Allow
```

---

## Rate Limiting MCP

Prevent runaway agents from exhausting upstream APIs.

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: mcp-rate-limit
  namespace: agentgateway-system
spec:
  targetRefs:
  - kind: HTTPRoute
    name: mcp-routes
  backend:
    mcp:
      rateLimit:
        requestsPerMinute: 30   # Sustainable pace
        burstSize: 10           # Allow short bursts
        perUser: true           # Per-agent limits
      timeout:
        toolCallMs: 30000       # 30s max per call
```

---

## Example: Secure GitHub MCP

Complete example with authorization and rate limiting:

```yaml
# Backend
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: github-mcp
  namespace: agentgateway-system
spec:
  mcp:
    target:
      host: github-mcp.mcp.svc.cluster.local
      port: 8080
---
# Security Policy
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: github-mcp-security
  namespace: agentgateway-system
spec:
  targetRefs:
  - kind: HTTPRoute
    name: mcp-routes
  backend:
    mcp:
      toolAuth:
        defaultAction: Deny
        rules:
        # Allow safe operations
        - tools:
          - "get_repository"
          - "list_repositories"
          - "search_issues"
          - "get_issue"
          - "list_pull_requests"
          - "get_pull_request"
          action: Allow
        # Block dangerous operations
        - tools:
          - "delete_repository"
          - "create_repository"
          - "merge_pull_request"
          action: Deny
          response:
            message: "🚫 This operation requires human approval"
      rateLimit:
        requestsPerMinute: 30
        burstSize: 10
```

---

## Testing MCP Authorization

```bash
# Should succeed - read operation
curl -X POST $MCP_GATEWAY/mcp/github \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"get_repository","arguments":{"owner":"solo-io","repo":"agentgateway"}},"id":1}'

# Should be blocked - write operation
curl -X POST $MCP_GATEWAY/mcp/github \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"delete_repository","arguments":{"owner":"acme","repo":"production"}},"id":2}'
# Expected: 403 "Write operations require approval"
```
