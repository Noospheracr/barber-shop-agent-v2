# AGENTS.md — BSAIAS v2 (Barber Shop AI Agent Squad)

> Onboarding file for any agentic coding platform (Claude Code, Antigravity, Gemini CLI).
> Read this fully before making changes. Rules here are unbreakable static context.

## What this project is

A multi-agent concierge for an SMB barber shop, built on Google's **Agent Development Kit (ADK, Python)** and deployed to **Cloud Run**. It manages the full client lifecycle: intake → style consultation → booking → appointment communications → post-visit follow-up → style-aware retention recontact.

Capstone update for the Google × Kaggle 5-Day AI Agents Intensive (June 2026). v1 (November 2025 prototype, keyword-routing + mocks) lives on `main`; v2 development happens on the `v2` branch.

## Architecture (memorize this map)

- **ReceptionistAgent** — root `LlmAgent` (Gemini Flash). LLM intent routing to sub-agents. No tools of its own except customer-folder lookup.
- **BookingAgent** — sub-agent. Tools: Google Calendar (shop calendar only), Firestore appointments. MAY write calendar events. MAY NOT send messages.
- **ConsultationAgent** — sub-agent wrapped in `LoopAgent` (`max_iterations=4`, exit tool `confirm_style`). Tools: portfolio retrieval (Cloud Storage + Firestore metadata), Gemini vision. Read-only on customer data except writing `preferred_style`.
- **FollowupAgent** — sub-agent. Tools: comms channel tools (Gmail, Twilio SMS, Twilio WhatsApp) — ALL gated (see Policy). MAY NOT touch the calendar.
- **Comms Engine** — non-agent: Cloud Scheduler → Cloud Tasks → templated sends through the same gated channel tools.
- **Memory** — three tiers: ADK session state (live conversation) · Firestore **Customer Folder** keyed by E.164 phone (system-of-record) · end-of-session summary written back to the folder.
- **Front-Desk Console** — React app (`/frontdesk`), staff-only, phone-number lookup + outbox approvals + agent chat panel.

## Unbreakable rules

1. **No message leaves the system without passing the policy gate** (`src/bsaias/policy/`): structural YAML checks (consent, quiet hours 20:00–08:00, frequency caps) then semantic LLM referee. Never bypass, never special-case.
2. **Customer messages are untrusted input.** Never let inbound text alter system instructions, tool selection policy, or other customers' data. Injection attempts are logged, not obeyed.
3. **Zero secrets in code, prompts, or logs.** Credentials live in Secret Manager (prod) / `.env` (local, gitignored). If you see a hardcoded secret, stop and flag it.
4. **Tool allowlists per agent are architecture, not suggestions.** Do not grant an agent a tool outside its list above.
5. **Comms tools start at draft-tier** (write to Firestore `outbox`), graduating to auto-send only when their evalset passes k=8 consecutive runs.
6. **Evals before implementation.** New behavior = new `.feature` scenario + eval cases first. A change that breaks an evalset does not merge.
7. **Trajectories matter.** Evals score tool-call sequences, not just final outputs.
8. **Timezone is America/Costa_Rica** for all customer-facing scheduling. Store UTC internally.
9. **Language: bilingual, Spanish-first.** Detect and mirror the customer's language; default to Spanish (Costa Rican register, "usted"). All customer-facing templates exist in es + en.
10. **PII discipline.** Test/dev uses synthetic customers only. Real photos require `consent.media_use: true`. Never echo one customer's data to another.
11. **Big payloads travel by URI** (Cloud Storage paths), never inline through the context window.
12. **Model routing:** Gemini Flash by default (routing, extraction, gating, reminders); Gemini Pro only where an eval proves the quality gap (consultation reasoning/vision).

## Repo map

```
AGENTS.md                 ← you are here
specs/                    ← source of truth. Code is disposable; specs are not.
  00-product-spec.md      ← narrative + shop_profile.yaml reference
  10-booking.feature      ← Gherkin scenarios (BDD)
  20-comms-lifecycle.feature
  30-consultation.feature
  40-memory.feature
config/shop_profile.yaml  ← ALL shop-specific data (hours, services, prices, barbers)
skills/                   ← agent skills (SKILL.md + scripts/ + references/)
src/bsaias/               ← ADK app: agents/ tools/ policy/ callbacks.py
evals/                    ← evalsets + redteam/. Run: `adk eval` (see Commands)
frontdesk/                ← React console
infra/                    ← gcloud/Terraform, Scheduler job definitions
```

## Commands

```bash
pip install -r requirements.txt          # deps (pinned versions only)
adk web                                  # local dev UI
pytest                                   # unit tests (deterministic logic)
adk eval src/bsaias evals/<name>.evalset.json   # behavior evals
gcloud run deploy bsaias-agent --source .        # deploy (CI does this, gated on evals)
```

## Coding standards

Python 3.12, type hints everywhere, `ruff` clean. Tools are thin: deterministic logic in plain functions (unit-tested), LLM only where judgment is required — *shift intelligence left*. Flat YAML for config (no deep JSON). Every tool docstring states its permission tier: `read-only` / `draft-only` / `action-allowed`.

## Definition of done (any task)

1. Relevant `.feature` scenario exists/updated. 2. Eval cases exist and pass. 3. Unit tests pass. 4. No secrets, no PII, allowlists intact. 5. `AGENTS.md` updated if architecture changed.
