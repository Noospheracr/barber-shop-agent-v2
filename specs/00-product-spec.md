# BSAIAS v2 — Product Specification
> Narrative spec. Behavioral detail lives in the `.feature` files; shop data in `config/shop_profile.yaml`.
> Format follows the Day-5 whitepaper guidance: markdown narrative + flat YAML for structure.

## 1. Mission

Give an SMB barber shop the memory and follow-through of its best barber, at scale: every client recognized by phone number, every appointment confirmed and reminded, every fresh cut followed up, every regular recontacted at exactly the right day for their style.

## 2. Actors

```yaml
actors:
  customer:      # interacts via WhatsApp / SMS / email only
    surfaces: [whatsapp, sms, email]
  staff:         # barbers/owner; interacts via Front-Desk Console
    surfaces: [frontdesk_console]
  system:        # scheduled jobs (Cloud Scheduler → Cloud Tasks)
    surfaces: [comms_engine]
```

## 3. Core capabilities (traceability index)

```yaml
capabilities:
  routing:            {spec: null, note: "LLM intent routing by ReceptionistAgent; evals/routing"}
  booking:            {spec: 10-booking.feature}
  comms_lifecycle:    {spec: 20-comms-lifecycle.feature}
  consultation:       {spec: 30-consultation.feature}
  customer_memory:    {spec: 40-memory.feature}
```

## 4. Customer Folder — canonical schema (Firestore)

```yaml
collection: customers
doc_id: E.164 phone            # e.g. "+50688881234"
fields:
  profile:     {name, email, whatsapp_opt_in, created_at, referral_source}
  preferences: {preferred_style, style_category: short|medium|long,
                barber_id, notes, preferred_channel: whatsapp|sms|email,
                language: es|en}
  consent:     {transactional: bool, marketing: bool, media_use: bool,
                updated_at}
  last_interaction_summary: string   # written by session-end compaction
subcollections:
  services:  {date, service_id, style, style_category, barber_id, price_crc,
              notes, selfie_uri, rating}
  referrals: {referred_phone, date, reward_status}
  messages:  {channel, direction, template_id, body, status, ts}
outbox:      # top-level collection: draft-tier sends awaiting approval
  {customer_phone, channel, template_id, body, created_by_agent, status:
   pending|approved|rejected|sent, reviewed_by, ts}
```

## 5. Language policy

Spanish-first bilingual. Inbound language detected per message; replies mirror the customer; `preferences.language` stores the sticky default. All templates authored as pairs (`*_es`, `*_en`). Register: "usted" (Costa Rican courtesy), warm but professional per `shop_profile.brand_voice`.

## 6. Permission model

```yaml
tiers: [read-only, draft-only, action-allowed]
agents:
  receptionist:  {tools: [customer_lookup], tier_max: read-only}
  booking:       {tools: [calendar_list, calendar_create, calendar_delete,
                          customer_lookup, appointment_write], tier_max: action-allowed}
  consultation:  {tools: [portfolio_search, vision_compare, customer_lookup,
                          preferred_style_write], tier_max: action-allowed}
  followup:      {tools: [send_whatsapp, send_sms, send_email,
                          customer_lookup, outbox_write], tier_max: draft-only}
  comms_engine:  {tools: [send_whatsapp, send_sms, send_email],
                  tier_max: draft-only}   # graduates to action-allowed via pass^8
policy_gates:
  structural: [consent_check, quiet_hours, frequency_cap, channel_allowed]
  semantic:   gemini-flash referee — no third-party PII, no invented offers,
              on-brand tone, correct language
```

## 7. Non-functional requirements

```yaml
latency:   {p50_reply_s: 4, p95_reply_s: 10}
cost:      {target_per_conversation_usd: 0.03, model_default: gemini-flash}
privacy:   {test_data: synthetic_only, media_requires: consent.media_use}
observability: {tracing: cloud-trace (OTel), logs: cloud-logging,
                cost_metering: per-session}
deploy:    {runtime: cloud-run us-central1, ci_gate: "pytest + adk eval green"}
submission_scope: comms channels run sandboxed (Twilio sandbox, test Gmail);
                  architecture production-complete
```

## 8. Out of scope (v2)

Payments, multi-shop tenancy, A2UI generative interfaces, live WABA senders, voice channel. All listed as iteration paths in the Kaggle writeup.
