require_relative 'version'

module DaVinciPASTestKit
  class Metadata < Inferno::TestKit
    id :davinci_pas_test_kit
    title 'DaVinci PAS Test Kit'
    description <<~DESCRIPTION
      The Da Vinci Prior Authorization Support (PAS) Test Kit validates the
      conformance of systems to the PAS STU 2.0.1 FHIR IG. The test kit includes
      suites targeting each of the actors from the specification:

      - Servers (payers): Inferno will act as a client and make a series of
        requests to the server under test.
      - Clients (Provider systems, such as EMRs and other systems that place orders):
        Inferno will act as a server, including waiting for the client to make requests
        and responding back.

      In each case, content provided by the system under test will be checked individually
      for conformance and in aggregate to determine that the full set of features is
      supported.
      <!-- break -->
    DESCRIPTION
    suite_ids [:davinci_pas_server_suite_v201, :davinci_pas_client_suite_v201]
    tags ['PAS']
    last_updated '2025-01-27'
    version VERSION
    maturity 'Low'
    authors ['Inferno Team']
    repo 'https://github.com/inferno-framework/davinci-pas-test-kit'
  end
end
