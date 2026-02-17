# AgentGateway Enterprise Features

Solo.io Enterprise edition features beyond open source.

## Table of Contents
- [EnterpriseAgentgatewayParameters](#enterpriseagentgatewayparameters)
- [EnterpriseAgentgatewayPolicy](#enterpriseagentgatewaypolicy)
- [UI Setup](#ui-setup)
- [Tracing (OTLP)](#tracing-otlp)
- [Advanced Auth](#advanced-auth)
- [Rate Limiting](#rate-limiting)
- [RBAC Access Control](#rbac-access-control)

---

## EnterpriseAgentgatewayParameters

Configure gateway-level settings like environment variables, telemetry, and deployment options.

```yaml
apiVersion: enterpriseagentgateway.solo.io/v1alpha1
kind: EnterpriseAgentgatewayParameters
metadata:
  name: gateway-params
  namespace: agentgateway-system
spec:
  # Environment variables for the gateway pod
  env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-collector.telemetry:4317"
  - name: OTEL_TRACES_EXPORTER
    value: "otlp"
  - name: OTEL_SERVICE_NAME
    value: "ai-gateway"
  
  # Logging configuration
  logging:
    level: info  # debug, info, warn, error
    format: json  # json or text
  
  # Deployment customization
  deployment:
    metadata:
      labels:
        team: platform
      annotations:
        prometheus.io/scrape: "true"
```

### Reference from Gateway
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: ai-gateway
  namespace: agentgateway-system
spec:
  gatewayClassName: enterprise-agentgateway
  infrastructure:
    parametersRef:
      group: enterpriseagentgateway.solo.io
      kind: EnterpriseAgentgatewayParameters
      name: gateway-params
  listeners:
  - name: http
    port: 8080
    protocol: HTTP
```

---

## EnterpriseAgentgatewayPolicy

Extended policy capabilities beyond open source AgentgatewayPolicy.

```yaml
apiVersion: enterpriseagentgateway.solo.io/v1alpha1
kind: EnterpriseAgentgatewayPolicy
metadata:
  name: enterprise-security
  namespace: agentgateway-system
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: ai-routes
  
  # Traffic policies
  traffic:
    # Rate limiting
    rateLimit:
      requestsPerUnit: 100
      unit: MINUTE
    
    # Timeouts
    timeouts:
      request: 60s
      backend: 120s
    
    # Retry configuration
    retry:
      attempts: 3
      perTryTimeout: 30s
      retryOn: ["5xx", "reset", "connect-failure"]
  
  # Backend policies  
  backend:
    ai:
      promptGuard:
        request:
        - regex:
            action: Reject
            builtins: [CreditCard, Ssn]
```

---

## UI Setup

### Install UI Components
```bash
helm upgrade --install agentgateway \
  oci://us-docker.pkg.dev/solo-public/helm-charts/agentgateway \
  -n agentgateway-system \
  --set ui.enabled=true \
  --set license.key=$AGENTGATEWAY_LICENSE
```

### Access UI
```bash
# Port forward
kubectl port-forward -n agentgateway-system svc/agentgateway-ui 8080:80

# Or expose via NodePort
kubectl patch svc agentgateway-ui -n agentgateway-system \
  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"nodePort":30080}]}}'
```

### UI Features
- Real-time request monitoring
- Policy visualization
- Backend health status
- Token usage metrics
- Trace exploration

---

## Tracing (OTLP)

### Deploy OpenTelemetry Collector
```bash
helm upgrade --install otel-collector opentelemetry-collector \
  --repo https://open-telemetry.github.io/opentelemetry-helm-charts \
  --version 0.127.2 \
  --set mode=deployment \
  --set image.repository="otel/opentelemetry-collector-contrib" \
  --namespace=telemetry \
  --create-namespace \
  -f - <<EOF
config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
  exporters:
    debug:
      verbosity: detailed
    # Add your backend: jaeger, zipkin, etc.
  service:
    pipelines:
      traces:
        receivers: [otlp]
        exporters: [debug]
EOF
```

### Configure Gateway for Tracing
```yaml
apiVersion: enterpriseagentgateway.solo.io/v1alpha1
kind: EnterpriseAgentgatewayParameters
metadata:
  name: tracing-params
  namespace: agentgateway-system
spec:
  env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-collector.telemetry.svc.cluster.local:4317"
  - name: OTEL_TRACES_EXPORTER
    value: "otlp"
  - name: OTEL_SERVICE_NAME
    value: "agentgateway"
```

### Trace Attributes
AI-specific attributes in traces:
- `gen_ai.operation.name` — chat, completion, embedding
- `gen_ai.provider.name` — openai, anthropic, etc.
- `gen_ai.request.model` — requested model
- `gen_ai.response.model` — actual model used
- `gen_ai.usage.input_tokens` — prompt tokens
- `gen_ai.usage.output_tokens` — completion tokens

---

## Advanced Auth

### API Key Authentication
```yaml
apiVersion: enterpriseagentgateway.solo.io/v1alpha1
kind: EnterpriseAgentgatewayPolicy
metadata:
  name: apikey-auth
spec:
  targetRefs:
  - kind: HTTPRoute
    name: ai-routes
  traffic:
    apiKeyAuthentication:
      headerName: x-api-key
      secretRefs:
      - name: valid-api-keys
```

### JWT Authentication
```yaml
apiVersion: enterpriseagentgateway.solo.io/v1alpha1
kind: EnterpriseAgentgatewayPolicy
metadata:
  name: jwt-auth
spec:
  targetRefs:
  - kind: HTTPRoute
    name: ai-routes
  traffic:
    jwtAuthentication:
      providers:
      - name: auth0
        issuer: "https://your-tenant.auth0.com/"
        audiences: ["your-api"]
        jwksUri: "https://your-tenant.auth0.com/.well-known/jwks.json"
```

### OAuth2 / OIDC
```yaml
traffic:
  extAuth:
    oauth:
      clientId: "..."
      clientSecretRef:
        name: oauth-secret
      issuerUrl: "https://accounts.google.com"
      scopes: ["openid", "email"]
```

---

## Rate Limiting

### Request-Based Rate Limiting
```yaml
apiVersion: enterpriseagentgateway.solo.io/v1alpha1
kind: EnterpriseAgentgatewayPolicy
metadata:
  name: rate-limit
spec:
  targetRefs:
  - kind: HTTPRoute
    name: ai-routes
  traffic:
    rateLimit:
      requestsPerUnit: 60
      unit: MINUTE
```

### Token-Based Rate Limiting
```yaml
backend:
  ai:
    rateLimit:
      tokensPerMinute: 100000
      tokensPerDay: 1000000
      perUser: true  # Per API key
```

### Per-User Rate Limiting
```yaml
traffic:
  entRateLimit:
    rateLimits:
    - actions:
      - requestHeaders:
          headerName: x-api-key
          descriptorKey: api_key
      limit:
        requestsPerUnit: 100
        unit: MINUTE
```

---

## RBAC Access Control

Control which models/providers users can access based on JWT claims.

```yaml
apiVersion: enterpriseagentgateway.solo.io/v1alpha1
kind: EnterpriseAgentgatewayPolicy
metadata:
  name: rbac-models
spec:
  targetRefs:
  - kind: HTTPRoute
    name: ai-routes
  traffic:
    authorization:
      rules:
      # Premium users get GPT-4
      - when:
        - key: request.auth.claims.tier
          values: ["premium", "enterprise"]
        to:
        - operation:
            paths: ["/openai/*"]
      # All users get GPT-3.5
      - when:
        - key: request.auth.claims.tier
          values: ["*"]
        to:
        - operation:
            paths: ["/openai-basic/*"]
```
