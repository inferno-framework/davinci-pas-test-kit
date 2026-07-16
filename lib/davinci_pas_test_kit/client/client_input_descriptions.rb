# frozen_string_literal: true

module DaVinciPASTestKit
  INPUT_CLIENT_ID_LOCKED =
    'The client\'s registered Client Id for use in obtaining access tokens. ' \
    'Run the **1** Client Registration group to configure this input.'
  INPUT_SESSION_URL_PATH_LOCKED =
    'The additional path used to create session-specific endpoints. Run the ' \
    '**1** Client Registration group to configure this input.'

  # Shared documentation for the must support response inputs, which differ only
  # in the operation whose responses they configure ('$submit' or '$inquire').
  def self.ms_responses_input_description(operation)
    <<~DESCRIPTION
      An optional JSON value specifying response Bundles for Inferno to return when
      responding to #{operation} requests during must support testing. Provide a single entry
      or a list of entries, where each entry is either a FHIR Bundle or a wrapper object
      of the form `{"criteria": {...}, "bundle": {...}}` pairing a FHIR Bundle with the
      selection criteria that a request must meet for that Bundle to be returned.

      For each request, Inferno will respond with the Bundle of the first entry whose
      criteria are all met. An entry with no criteria (including a bare Bundle) matches
      any request, and an entry with multiple criteria must meet all of them. If no entry
      matches, or none are provided, Inferno will generate a default response. Supported
      `criteria` keys:

      - `requestRange`: a string of comma-separated request numbers or ranges, e.g.,
        `"1-2,4"`. Met when the number of #{operation} requests received during this test,
        counting this one, is among the listed values.
      - `fhirpath`: a FHIRPath expression evaluated against the incoming request Bundle.
        Met when the expression evaluates to a single truthy value.

      A Bundle may also contain tokens of the form `{{fhirpath}}`, e.g.,
      `{{Bundle.entry.first().resource.id}}`. Inferno replaces each token in the returned
      Bundle with the result of evaluating the FHIRPath expression against the incoming
      request Bundle.
    DESCRIPTION
  end
end
