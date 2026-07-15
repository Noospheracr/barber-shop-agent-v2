Feature: Customer memory (three-tier)
  Session state for the live conversation; the Firestore Customer Folder as
  system-of-record; end-of-session summarization for continuity.

  Scenario: Returning customer is recognized by phone number
    Given a customer folder exists for "+50688881234" with preferred_style "fade medio"
    When that number writes after 4 months of silence
    Then the greeting acknowledges them by name
    And the agent can reference their preferred style and last service without asking
    And the reply uses their stored language preference

  Scenario: First contact auto-creates the folder
    Given no folder exists for the inbound number
    When any message arrives from it
    Then a folder is created keyed by the E.164 number
    And profile.created_at and referral_source (if detectable) are set

  Scenario: End-of-session compaction
    Given a conversation ends or times out
    Then a summary of at most 100 words is written to last_interaction_summary
    And the raw transcript is not injected into future sessions

  Scenario: Service completion updates history
    Given an appointment is marked completed
    Then a service document is appended with date, service, style, style_category,
      barber and price
    And the recontact cadence for that service cycle is scheduled from this record

  Scenario: Staff lookup provides full continuity
    Given a staff member searches "+50688881234" in the Front-Desk Console
    Then they see profile, preferences, consent flags, service timeline,
      message history, upcoming appointment and pending outbox items

  Scenario: Referral tracking
    Given customer A refers customer B and B books a first appointment
    When B's appointment completes
    Then a referral document under A is updated to reward_status "earned"

  Scenario: Tenant isolation of personal data
    When any agent composes a message to customer A
    Then the draft contains no data originating from any other customer's folder
