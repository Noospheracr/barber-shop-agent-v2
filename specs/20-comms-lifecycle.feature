Feature: Communications lifecycle (the retention engine)
  Cloud Scheduler → Cloud Tasks drive every send. All sends pass the structural
  and semantic policy gates. All sends are draft-tier (outbox) until the comms
  evalset has passed 8 consecutive runs (pass^8).

  Background:
    Given the shop profile is loaded from config/shop_profile.yaml
    And quiet hours are 20:00-08:00 America/Costa_Rica

  Scenario: Booking confirmation, preferred channel
    Given a customer with preferred_channel "whatsapp" and transactional consent
    When an appointment is confirmed
    Then a confirmation is queued immediately on whatsapp
    And the message contains service, date, time, barber and the maps link
    And the message is in the customer's stored language

  Scenario Outline: Pre-appointment reminders
    Given a confirmed appointment at <time>
    When the reminder job runs at <offset> before the appointment
    Then a reminder is queued on the preferred channel
    And the T-2.5h reminder includes a one-tap cancel option
    Examples:
      | time  | offset |
      | 15:00 | 24h    |
      | 15:00 | 2.5h   |

  Scenario: Post-visit follow-up with selfie offer
    Given an appointment marked completed at 14:00
    When the follow-up job runs at 17:00
    Then a thank-you message is queued asking for a rating
    And it offers the selfie discount from shop_profile.retention
    And it requests media consent if consent.media_use is false

  Scenario: Style-based recontact — short cut
    Given a completed service with style_category "short" on day 0
    And the customer has marketing consent
    When the daily recontact job runs on day 15
    Then a "sharpen-up" nudge with a booking link is queued
    And no second recontact is queued for the same service cycle

  Scenario: Style-based recontact — medium/long cut
    Given a completed service with style_category "medium" on day 0
    When the daily recontact job runs on day 21
    Then a fresh-cut nudge is queued

  Scenario: No marketing consent means no recontact
    Given a customer with marketing consent false
    When the recontact job runs on their cadence day
    Then no message is queued
    And the skip reason "no_marketing_consent" is logged

  Scenario: Quiet hours defer, not drop
    Given a message becomes due at 21:30 local time
    Then it is scheduled for 08:00 the next morning, not sent and not dropped

  Scenario: Structural gate blocks channel without consent
    Given a customer consented to whatsapp but not sms
    When a send is attempted on sms
    Then the send is blocked by the structural gate
    And the event is logged with reason "channel_consent"

  Scenario: Semantic gate blocks a leaking draft
    Given a drafted message that mentions another customer's name
    When the semantic gate inspects the draft
    Then the send is blocked and routed to the outbox for human review

  Scenario: Draft tier before graduation
    Given comms tools have not yet passed pass^8
    When any send is triggered
    Then the message is written to the outbox with status "pending"
    And nothing reaches Twilio or Gmail until staff approve it in the console
