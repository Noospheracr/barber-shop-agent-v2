Feature: Style consultation (bounded loop, portfolio-grounded)
  The ConsultationAgent runs as a LoopAgent: propose → react → refine,
  max_iterations 4, exit via the confirm_style tool. Advice is grounded in the
  shop's own consented portfolio, never invented.

  Background:
    Given the portfolio collection contains media with consent flag media_use true only

  Scenario: Consultation with customer photo and portfolio references
    Given a customer sends a photo asking "qué corte me recomienda?"
    When the ConsultationAgent runs
    Then portfolio_search retrieves 2-3 references matching the request
    And the vision comparison reasons over the customer photo and the references
    And the proposal cites which portfolio references it is based on
    And the reply is in Spanish

  Scenario: Loop converges within bounds
    Given a consultation in progress
    When the customer accepts a proposal ("sí, ese me gusta")
    Then confirm_style is called with the agreed style
    And preferences.preferred_style and style_category are updated in the folder
    And the agent offers to hand off to booking

  Scenario: Loop hits max iterations without agreement
    Given the customer has rejected 4 consecutive proposals
    Then the loop exits gracefully
    And the agent offers an in-person consultation with a barber instead
    And no preferred_style is written

  Scenario: No matching portfolio references
    Given no portfolio media matches the requested style
    Then the agent says so honestly and describes the style verbally
    And does not fabricate references or show non-consented media

  Scenario: Text-only consultation (no photo)
    When a customer describes a style in words without sending a photo
    Then the agent may retrieve references by tags alone
    And may ask at most one clarifying question per loop iteration

  Scenario: Consent boundary on media
    Given a portfolio item with media_use false exists matching the request
    Then that item never appears in retrieval results
