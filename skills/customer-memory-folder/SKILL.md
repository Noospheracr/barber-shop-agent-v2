---
name: customer-memory-folder
description: >
  Maintain a per-customer system-of-record ("Customer Folder") keyed by E.164
  phone number in Firestore: profile, preferences, consent, service history,
  referrals, message log, and end-of-session summaries. Use on first contact
  (auto-create), on any preference/consent change, on service completion, and
  at session end (compaction). Do NOT store secrets or third-party data.
version: 0.1.0
license: CC0-1.0
---

# Customer Memory Folder

## When to trigger
Inbound contact from an unknown number (auto-create) · returning-customer
recognition · preference/consent updates · service completion · session end.

## Instructions
1. Key everything by the E.164 phone number of the sender. Never write to a folder other than the active customer's.
2. On first contact: create the folder with `created_at`, detected `language`, and `referral_source` if inferable; ask for the name naturally in conversation.
3. On recognition: load `profile`, `preferences`, `last_interaction_summary` into session state — NOT raw transcripts.
4. On service completion: append a `services/` document (date, service_id, style, style_category, barber, price, rating, selfie_uri) via `scripts/record_service.py`; this record drives the recontact cadence.
5. At session end: write a ≤100-word `last_interaction_summary` (compaction). The summary must contain no other customer's data.
6. Consent flags (`transactional`, `marketing`, `media_use`) change only on explicit customer statements; log the change with a timestamp.
7. Referrals: link referrer → referred; mark `reward_status: earned` when the referred customer's first appointment completes.

## Contents (to author in P2)
- `scripts/folder_crud.py` — typed Firestore accessors (create/read/update)
- `scripts/record_service.py` — service append + cadence scheduling hook
- `references/schema.yaml` — canonical schema (mirrors specs/00-product-spec.md §4)

## Portability note
The schema is service-business-generic; `preferred_style` generalizes to any
"preferred configuration" field (treatment, table, trainer, prescription).
