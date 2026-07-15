---
name: appointment-lifecycle-comms
description: >
  Manage the full appointment communications lifecycle for a service business:
  booking confirmation, T-24h and T-2.5h reminders (with one-tap cancel),
  post-visit follow-up with review + selfie-offer, and style/interval-based
  recontact nudges. Use when an appointment is created, completed, cancelled,
  or when a scheduled comms job fires. Do NOT use for ad-hoc conversational
  replies — those belong to the active agent.
version: 0.1.0
license: CC0-1.0
---

# Appointment Lifecycle Comms

## When to trigger
Appointment state changes (`confirmed`, `completed`, `cancelled`) and scheduled
jobs (`reminder_24h`, `reminder_2_5h`, `followup_3h`, `daily_recontact`).

## Instructions
1. Load the customer's folder; resolve `preferred_channel`, `language`, consent flags.
2. Select the template pair (`<template>_es` / `<template>_en`) matching the event; fill variables from the appointment and `config/shop_profile.yaml` ONLY — never invent offers, prices, or times.
3. Run the structural gate script (`scripts/structural_gate.py`) — consent, quiet hours, frequency cap, channel allowed. If blocked: log reason, stop.
4. Submit the draft to the semantic gate. If flagged: route to outbox for human review.
5. Queue via Cloud Tasks. While the skill is below its pass^8 graduation, ALL sends go to the outbox with status `pending`.
6. Recontact cadence: `short → +15d`, `medium|long → +21d` from service completion; max one marketing message per service cycle.

## Contents (to author in P3)
- `scripts/structural_gate.py` — deterministic consent/quiet-hours/frequency checks
- `scripts/schedule_cadence.py` — computes Cloud Tasks ETAs from a service record
- `references/templates_es.yaml`, `references/templates_en.yaml`
- `references/policy.yaml` — quiet hours, caps, channel rules
- `evals/` — see `evals/comms_policy.evalset.json` at repo root

## Portability note
Shop-agnostic by design: everything specific comes from `shop_profile.yaml` and
the templates. Reusable for salons, dental clinics, personal trainers, etc.
