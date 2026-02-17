# AgentGateway AI Providers

Complete configuration for all supported LLM providers.

## Table of Contents
- [OpenAI](#openai)
- [Anthropic](#anthropic)
- [Azure OpenAI](#azure-openai)
- [AWS Bedrock](#aws-bedrock)
- [Google Gemini](#google-gemini)
- [Google Vertex AI](#google-vertex-ai)
- [OpenAI-Compatible (Ollama, Mistral, DeepSeek)](#openai-compatible)
- [Multi-Provider Failover](#multi-provider-failover)

---

## OpenAI

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
        model: gpt-4o  # optional: gpt-4o-mini, gpt-4-turbo, o1-preview
  policies:
    auth:
      secretRef:
        name: openai-api-key
---
apiVersion: v1
kind: Secret
metadata:
  name: openai-api-key
  namespace: agentgateway-system
type: Opaque
stringData:
  api-key: "sk-..."
```

**Models:** gpt-4o, gpt-4o-mini, gpt-4-turbo, gpt-3.5-turbo, o1-preview, o1-mini

---

## Anthropic

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: anthropic
  namespace: agentgateway-system
spec:
  ai:
    provider:
      anthropic:
        model: claude-sonnet-4-20250514  # optional
  policies:
    auth:
      secretRef:
        name: anthropic-api-key
---
apiVersion: v1
kind: Secret
metadata:
  name: anthropic-api-key
  namespace: agentgateway-system
type: Opaque
stringData:
  api-key: "sk-ant-..."
```

**Models:** claude-sonnet-4-20250514, claude-opus-4-20250514, claude-3-haiku

---

## Azure OpenAI

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: azure-openai
  namespace: agentgateway-system
spec:
  ai:
    provider:
      azureopenai:
        deploymentName: gpt-4o-deployment
        apiVersion: "2024-02-15-preview"
        endpoint: myresource.openai.azure.com
  policies:
    auth:
      secretRef:
        name: azure-openai-key
---
apiVersion: v1
kind: Secret
metadata:
  name: azure-openai-key
  namespace: agentgateway-system
type: Opaque
stringData:
  api-key: "..."
```

---

## AWS Bedrock

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: bedrock
  namespace: agentgateway-system
spec:
  ai:
    provider:
      bedrock:
        region: us-east-1
  policies:
    auth:
      aws:
        region: us-east-1
        # Uses IRSA or instance profile by default
        # Or explicit credentials:
        secretRef:
          name: aws-credentials
---
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: agentgateway-system
type: Opaque
stringData:
  aws-access-key-id: "AKIA..."
  aws-secret-access-key: "..."
```

**Models:** anthropic.claude-3-sonnet, anthropic.claude-3-haiku, amazon.titan-text-express

---

## Google Gemini

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: gemini
  namespace: agentgateway-system
spec:
  ai:
    provider:
      gemini:
        project: my-gcp-project
  policies:
    auth:
      secretRef:
        name: gemini-api-key
---
apiVersion: v1
kind: Secret
metadata:
  name: gemini-api-key
  namespace: agentgateway-system
type: Opaque
stringData:
  api-key: "AIza..."
```

**Models:** gemini-1.5-pro, gemini-1.5-flash, gemini-pro

---

## Google Vertex AI

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: vertex
  namespace: agentgateway-system
spec:
  ai:
    provider:
      vertexai:
        project: my-gcp-project
        location: us-central1
  policies:
    auth:
      gcp:
        # Uses Workload Identity by default
        # Or explicit service account:
        serviceAccountSecretRef:
          name: gcp-sa-key
```

---

## OpenAI-Compatible

For Ollama, Mistral, DeepSeek, vLLM, or any OpenAI-compatible endpoint.

### Ollama (Local)
```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: ollama
  namespace: agentgateway-system
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

**Usage:** Request with `"model": "llama3.2:1b"` or `"model": "llama3.1:8b"`

### Mistral AI
```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: mistral
  namespace: agentgateway-system
spec:
  ai:
    provider:
      openai: {}
      host: api.mistral.ai
      port: 443
  policies:
    auth:
      secretRef:
        name: mistral-api-key
    tls: {}  # Enable TLS for external endpoint
```

### DeepSeek
```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: deepseek
  namespace: agentgateway-system
spec:
  ai:
    provider:
      openai: {}
      host: api.deepseek.com
      port: 443
  policies:
    auth:
      secretRef:
        name: deepseek-api-key
    tls: {}
```

---

## Multi-Provider Failover

Configure automatic failover between providers:

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: resilient-ai
  namespace: agentgateway-system
spec:
  ai:
    groups:
    # Primary: OpenAI
    - providers:
      - openai:
          model: gpt-4o
        policies:
          auth:
            secretRef:
              name: openai-api-key
    # Fallback 1: Anthropic
    - providers:
      - anthropic:
          model: claude-sonnet-4-20250514
        policies:
          auth:
            secretRef:
              name: anthropic-api-key
    # Fallback 2: Azure OpenAI
    - providers:
      - azureopenai:
          deploymentName: gpt-4o
          apiVersion: "2024-02-15-preview"
          endpoint: backup.openai.azure.com
        policies:
          auth:
            secretRef:
              name: azure-openai-key
```

**Behavior:** If OpenAI fails (timeout, rate limit, error), automatically tries Anthropic, then Azure.

---

## HTTPRoute Examples

### Single Provider
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: openai-route
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

### Multi-Provider Gateway
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: multi-llm-route
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
  - matches:
    - path:
        type: PathPrefix
        value: /anthropic
    backendRefs:
    - group: agentgateway.dev
      kind: AgentgatewayBackend
      name: anthropic
  - matches:
    - path:
        type: PathPrefix
        value: /ollama
    backendRefs:
    - group: agentgateway.dev
      kind: AgentgatewayBackend
      name: ollama
```
