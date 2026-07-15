# barber-shop-agent-v2
Rebuilding a multi-agent barber concierge with ADK, Firestore memory, lifecycle messaging, and evaluation-driven guardrails on GCP.
## What's here


| Path                         | Purpose                                                             | Status                                          |
|------------------------------|---------------------------------------------------------------------|-------------------------------------------------|
| `AGENTS.md`                  | Tool-agnostic onboarding for Claude Code / Antigravity / Gemini CLI | Ready                                           |
| `config/shop_profile.yaml`   | All shop-specific data                                              | In process |
| `specs/00-product-spec.md`   | Narrative spec + schemas + permission model                         | Ready                                           |
| `specs/10–40 *.feature`    | Gherkin scenarios: booking, comms, consultation, memory             | Ready for review                                |
| `evals/*.evalset.json`       | Pre-implementation eval cases (routing, booking, comms policy)      | Convert to ADK schema in P1                     |
| `evals/redteam/prompts.yaml` | Injection/exfiltration attack suite for CI                          | Ready                                           |
| `skills/*/SKILL.md`          | Three open-source skill skeletons (scripts authored in P2–P4)     | Skeletons                                       |
