---
name: style-consultation-loop
description: >
  Run a bounded propose→react→refine style consultation grounded in a consented
  portfolio of the business's own work. Use when a customer asks for style
  advice, sends a photo asking what would suit them, or wants to browse looks.
  Do NOT use for booking, pricing, or feedback intents.
version: 0.1.0
license: CC0-1.0
---

# Style Consultation Loop

## When to trigger
Style-advice intents: "¿qué corte me recomienda?", customer photo + question,
"quiero un cambio de look", browsing styles before booking.

## Instructions
1. Operate inside a `LoopAgent` with `max_iterations: 4` and exit tool `confirm_style`.
2. Retrieve 2–3 portfolio references via `scripts/portfolio_search.py` (tag filter first; embedding similarity if available). Only items with `media_use: true` are ever eligible.
3. If the customer sent a photo, run the vision comparison: customer photo vs references; reason about face shape, hair type, maintenance level. Cite which references ground the proposal.
4. One proposal per iteration; at most one clarifying question per iteration.
5. On acceptance: call `confirm_style` → write `preferred_style` + `style_category` (short|medium|long) to the customer folder → offer booking handoff.
6. On 4 rejections: exit gracefully, offer an in-person consultation, write nothing.
7. Never fabricate references; if no match exists, say so and describe verbally.
8. Large media travels by GCS URI only — never inline through context.

## Contents (to author in P4)
- `scripts/portfolio_search.py` — Firestore tag query (+ optional multimodal embedding)
- `references/style_taxonomy.yaml` — style names es/en → style_category mapping
- `references/consultation_rubric.md` — LLM-as-judge rubric for eval scoring

## Portability note
Swap the portfolio and taxonomy: works for tattoo studios, opticians,
interior designers — any "show me what suits me" business.
