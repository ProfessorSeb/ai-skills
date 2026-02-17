# AgentGateway Skill for OpenClaw

AI-first gateway skill for routing to LLMs, MCP tools, and agents in Kubernetes.

## Installation

```bash
clawdhub install agentgateway
```

Or clone directly:
```bash
git clone https://github.com/ProfessorSeb/agentgateway-skill.git ~/.openclaw/workspace/skills/agentgateway
```

## Coverage

| Feature | Open Source | Enterprise |
|---------|-------------|------------|
| AI Provider Routing | ✅ | ✅ |
| Prompt Guards (PII, Jailbreak) | ✅ | ✅ |
| Prompt Enrichment | ✅ | ✅ |
| Model Failover | ✅ | ✅ |
| MCP Tool Routing | ✅ | ✅ |
| Rate Limiting | Basic | Advanced |
| Tracing (OTLP) | - | ✅ |
| UI Dashboard | - | ✅ |
| Advanced Auth (OAuth/JWT) | - | ✅ |
| RBAC Access Control | - | ✅ |

## Supported Providers

- OpenAI (GPT-4o, o1)
- Anthropic (Claude)
- Azure OpenAI
- AWS Bedrock
- Google Gemini
- Google Vertex AI
- OpenAI-Compatible (Ollama, Mistral, DeepSeek, vLLM)

## Documentation

- [SKILL.md](SKILL.md) — Main skill instructions
- [references/security.md](references/security.md) — Security policies
- [references/providers.md](references/providers.md) — Provider configurations
- [references/enterprise.md](references/enterprise.md) — Enterprise features
- [references/mcp.md](references/mcp.md) — MCP tool configuration

## Links

- Open Source: https://agentgateway.dev
- Enterprise: https://docs.solo.io/agentgateway
