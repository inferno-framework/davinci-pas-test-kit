require_relative 'version'

module DaVinciPASTestKit
  class Metadata < Inferno::TestKit
    id :davinci_pas_test_kit
    title 'Da Vinci Prior Authorization Support (PAS) Test Kit'
    description <<~DESCRIPTION
      The Da Vinci Prior Authorization Support (PAS) Test Kit validates
      the conformance of both PAS client and server implementations to
      [version 2.0.1 of the Da Vinci PAS Implementation
      Guide](https://hl7.org/fhir/us/davinci-pas/STU2/).

      <!-- break -->

      To validate the behavior of a system Inferno will act as the partner to the
      system under test:
      - **When testing a client**: Inferno will act as a server, awaiting requests
        from the client under test, returning appropriate responses, and validating
        the conformance of the client's requests and its ability to handle the
        responses appropriately.
      - **When testing a server**: Inferno will act as a client, making requests
        against the server under test and validating the conformance and
        appropriateness of the server's responses.

      The test suites for both PAS clients and servers follow the same basic outline,
      each testing:

      - The implementation's ability to use PAS-defined APIs to participate in the
        submission of and decision on a prior authorization request, including:
        - Approval of a prior authorization request.
        - Denial of a prior authorization request.
        - Pending of a prior authorization request and a subsequent final decision.
      - The implementation ability to provide and handle data covering the full scope
        of PAS must support requirements on:
        - Prior authorization submissions.
        - Prior authorization inquiries.

      The Da Vinci PAS Test Kit is built using the [Inferno
      Framework](https://inferno-framework.github.io/). The Inferno Framework is
      designed for reuse and aims to make it easier to build test kits for any
      FHIR-based data exchange.

      ## Known Limitations

      The following areas of the IG are not fully tested in this draft version of the test kit:

      - Private X12 details including value set expansions
      - The use of Subscriptions to alert clients of updates to pended requests
      - Prior Authorization update workflows
      - Requests for additional information handled through the CDex framework
      - PDF, CDA, and JPG attachments
      - US Core profile support for supporting information
      - Server inquiry matching and subsetting logic
      - Server inquiry requests from non-submitting systems
      - Server collection of metrics
      - Client handling of responses containing all PAS-defined profiles and must support elements
      - Client handling of situations that requiring manual review of the client system,
        e.g., the requirement that clinicians can update details of the prior authorization
        request before submitting them

      For additional details on these and other areas where the tests may not align with
      the IGs requirements, see documentation in the test kit source code ([client](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/lib/davinci_pas_test_kit/docs/client_suite_description_v201.md#testing-limitations), [server](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/lib/davinci_pas_test_kit/docs/server_suite_description_v201.md#testing-limitations)), and [this requirements analysis
      spreadsheet](https://github.com/inferno-framework/davinci-pas-test-kit/blob/main/lib/davinci_pas_test_kit/docs/PAS%20Requirements%20Interpretation.xlsx).

      ### Known IG Issues

      Through testing with this test kit, issues have been identified in the version of the PAS
      specification that this test kit tests against which cause false failures. The full list
      of known issues can be found on the [repository's issues page with the 'source ig issue'
      lable](https://github.com/inferno-framework/davinci-pas-test-kit/labels/source%20ig%20issue).

      ## Reporting Issues

      Please report any issues with this set of tests in the [GitHub
      Issues](https://github.com/inferno-framework/davinci-pas-test-kit/issues)
      section of the
      [open source code repository](https://github.com/inferno-framework/davinci-pas-test-kit).
    DESCRIPTION
    suite_ids [:davinci_pas_server_suite_v201, :davinci_pas_client_suite_v201]
    tags ['Da Vinci', 'PAS']
    last_updated '2025-01-27'
    version VERSION
    maturity 'Low'
    authors ['Inferno Team']
    repo 'https://github.com/inferno-framework/davinci-pas-test-kit'
  end
end
