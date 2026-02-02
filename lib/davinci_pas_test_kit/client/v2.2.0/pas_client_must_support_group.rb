require_relative '../generated/v2.2.0/pas_client_submit_must_support_group'
require_relative '../generated/v2.2.0/pas_client_inquire_must_support_group'

module DaVinciPASTestKit
  module DaVinciPASV220
    class PASClientMustSupportGroup < Inferno::TestGroup
      id :pas_client_v220_must_support
      title 'Must Support Elements'
      description %(
        During these tests, the client will show that it supports all PAS-defined profiles and the must support
        elements defined in them. This includes

        - The ability to make prior authorization submission and inquiry requests that contain all
          PAS-defined profiles and their must support elements.
        - The ability to receive in responses to those requests all PAS-defined profiles and their
          must support elements and continue the prior authorization workflow as appropriate (not currently
          implemented in these tests).

        Clients under test will be asked to make additional requests to Inferno demonstrating coverage
        of all must support items in the requests. Note that Inferno will consider requests made during
        the workflow group of tests, so only profiles and must support elements not demonstrated during
        those tests need to be submitted as a part of these.
      )

      group from: :pas_client_v220_submit_must_support
      group from: :pas_client_v220_inquire_must_support
    end
  end
end
