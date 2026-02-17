---
name: agentgateway
description: |
  Solo.io AgentGateway skill for deploying and managing AI gateways in Kubernetes. Covers both open source (agentgateway.dev) and Enterprise (Solo.io) editions. Use when:
  (1) Installing AgentGateway via Helm or ArgoCD
  (2) Configuring AI providers: OpenAI, Anthropic, Azure OpenAI, Bedrock, Gemini, Vertex AI, Ollama/OpenAI-compatible
  (3) Creating Gateway, HTTPRoute, AgentgatewayBackend, AgentgatewayPolicy resources
  (4) Setting up MCP (Model Context Protocol) for tool access
  (5) Configuring security: prompt guards, PII protection, jailbreak prevention, credential leak protection
  (6) Rate limiting (request-based and token-based)
  (7) Prompt enrichment/elicitation for consistent AI behavior
  (8) Model failover and reliability patterns
  (9) Observability: tracing (OTLP), metrics, logging
  (10) Enterprise features: EnterpriseAgentgatewayPolicy, EnterpriseAgentgatewayParameters, UI setup
metadata:
  author: ProfessorSeb
  version: "1.0.0"
---

# AgentGateway Skill

AI-first gateway for routing to LLMs, MCP tools, and agents in Kubernetes.

## Quick Reference

| Edition | Docs | Helm Repo |
|---------|------|-----------|
| **Open Source** | https://agentgateway.dev | `oci://ghcr.io/agentgateway-dev/helm-charts/agentgateway` |
| **Enterprise** | https://docs.solo.io/agentgateway | `oci://us-docker.pkg.dev/solo-public/helm-charts/agentgateway` |

## Installation

### Open Source
```bash
# Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

# AgentGateway CRDs + Control Plane
helm upgrade --install agentgateway \
  oci://ghcr.io/agentgateway-dev/helm-charts/agentgateway \
  -n agentgateway-system --create-namespace
```

### Enterprise
```bash
# Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

# AgentGateway CRDs
helm upgrade --install agentgateway-crds \
  oci://us-docker.pkg.dev/solo-public/helm-charts/agentgateway-crds \
  -n agentgateway-system --create-namespace

# Control Plane (with license)
helm upgrade --install agentgateway \
  oci://us-docker.pkg.dev/solo-public/helm-charts/agentgateway \
  -n agentgateway-system \
  --set license.key=$AGENTGATEWAY_LICENSE
```

## Core Resources

### AgentgatewayBackend (AI Provider)

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: openai
  namespace: agentgateway-system
spec:
  ai:
    provider:
      openai:
        model: gpt-4o  # optional: override model
  policies:
    auth:
      secretRef:
        name: openai-api-key
        namespace: agentgateway-system
```

**Supported Providers:**
- `openai: {}` — OpenAI
- `anthropic: {}` — Anthropic Claude
- `azureopenai: {deploymentName, apiVersion, endpoint}` — Azure OpenAI
- `bedrock: {region}` — AWS Bedrock
- `gemini: {project}` — Google Gemini
- `vertexai: {project, location}` — Google Vertex AI
- `openai: {}` + custom `host`/`port` — OpenAI-compatible (Ollama, Mistral, DeepSeek)

### Gateway + HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: ai-gateway
  namespace: agentgateway-system
spec:
  gatewayClassName: agentgateway  # or enterprise-agentgateway
  listeners:
  - name: http
    port: 8080
    protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ai-routes
  namespace: agentgateway-system
spec:
  parentRefs:
  - name: ai-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /openai
    backendRefs:
    - group: agentgateway.dev
      kind: AgentgatewayBackend
      name: openai
```

## Security Policies

See [references/security.md](references/security.md) for complete examples.

### PII Protection
```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: block-pii
spec:
  targetRefs:
  - kind: HTTPRoute
    name: ai-routes
  backend:
    ai:
      promptGuard:
        request:
        - regex:
            action: Reject
            builtins: [CreditCard, Ssn, PhoneNumber]
          response:
            message: "🚫 PII detected - request blocked"
```

### Jailbreak Prevention
```yaml
backend:
  ai:
    promptGuard:
      request:
      - regex:
          action: Reject
          patterns:
          - "(?i)ignore.*previous.*instructions"
          - "(?i)you are now (DAN|evil)"
        response:
          message: "🚫 Prompt injection blocked"
```

### Credential Leak Protection
```yaml
patterns:
- "sk-[a-zA-Z0-9]{20,}"      # OpenAI keys
- "ghp_[a-zA-Z0-9]{36}"      # GitHub tokens
- "xoxb-[a-zA-Z0-9-]+"       # Slack tokens
```

## Prompt Enrichment

Inject system prompts at the gateway level:

```yaml
backend:
  ai:
    promptEnrichment:
      prepend:
      - role: system
        content: |
          You are a helpful assistant for Acme Corp.
          Always be professional and concise.
          Never discuss competitors.
```

## Rate Limiting

```yaml
backend:
  ai:
    rateLimit:
      requestsPerMinute: 60
      tokensPerMinute: 100000
      perUser: true  # rate limit per API key
```

## Model Failover

```yaml
spec:
  ai:
    groups:
    - providers:
      - openai:
          model: gpt-4o
    - providers:
      - anthropic:
          model: claude-sonnet-4-20250514
    # Falls back to Anthropic if OpenAI fails
```

## OpenAI-Compatible Backends (Ollama)

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: ollama
spec:
  ai:
    provider:
      openai: {}
      host: ollama.ollama.svc.cluster.local
      port: 11434
  policies:
    http:
      requestTimeout: 120s
```

Test: `curl $GATEWAY/ollama/v1/chat/completions -d '{"model":"llama3.2:1b","messages":[...]}'`

## MCP (Model Context Protocol)

See [references/mcp.md](references/mcp.md) for MCP tool configuration.

## Enterprise Features

See [references/enterprise.md](references/enterprise.md) for:
- EnterpriseAgentgatewayPolicy
- EnterpriseAgentgatewayParameters
- UI setup
- Advanced auth (OAuth, JWT)
- Tracing (OTLP)

## Observability

Gateway logs include AI-specific telemetry:
```
gen_ai.operation.name=chat
gen_ai.provider.name=openai
gen_ai.request.model=gpt-4o
gen_ai.usage.input_tokens=150
gen_ai.usage.output_tokens=42
duration=1250ms
```

### Enable OTLP Tracing (Enterprise)

```yaml
apiVersion: enterpriseagentgateway.solo.io/v1alpha1
kind: EnterpriseAgentgatewayParameters
metadata:
  name: gateway-params
  namespace: agentgateway-system
spec:
  env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-collector.telemetry:4317"
  - name: OTEL_TRACES_EXPORTER
    value: "otlp"
```

Reference in Gateway:
```yaml
spec:
  infrastructure:
    parametersRef:
      group: enterpriseagentgateway.solo.io
      kind: EnterpriseAgentgatewayParameters
      name: gateway-params
```

## Common Commands

```bash
# Check backends
kubectl get agentgatewaybackends -n agentgateway-system

# Check policies
kubectl get agentgatewaypolicies -n agentgateway-system

# Check gateways
kubectl get gateway -n agentgateway-system

# Gateway logs
kubectl logs -n agentgateway-system deploy/<gateway-name> | grep gen_ai

# Test endpoint
curl -X POST $GATEWAY/openai/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":"Hello"}]}'
```

## Troubleshooting

| Issue | Check |
|-------|-------|
| 404 on requests | HTTPRoute path matches, backend exists |
| 503 errors | Backend service reachable, timeout settings |
| Auth failures | Secret exists, key format correct |
| Policy not applied | targetRefs match route name/namespace |

## References

- [references/security.md](references/security.md) — Complete security policy examples
- [references/mcp.md](references/mcp.md) — MCP tool configuration
- [references/enterprise.md](references/enterprise.md) — Enterprise-only features
- [references/providers.md](references/providers.md) — All provider configurations
