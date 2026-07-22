module DaVinciPASTestKit
  module DaVinciPASV221
    class PASServerSubscriptionCapabilityStatementTest < Inferno::Test
      id :pas_server_v221_subscription_capability_statement_test
      title 'Server CapabilityStatement declares Subscription create, update, and delete support'
      description %(
          The PAS IG [requires](https://hl7.org/fhir/us/davinci-pas/2.2.1/en/specification.html#ci-c-spec-55)
          servers that support subscriptions to expose that support in their CapabilityStatement. This test retrieves
          the CapabilityStatement and verifies that its server-mode Subscription resource declares the create, update,
          and delete interactions.
        )

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@spec-55'

      REQUIRED_INTERACTIONS = ['create', 'update', 'delete'].freeze

      run do
        fhir_get_capability_statement

        assert_response_status(200) 
        assert_resource_type(:capability_statement)

        server_rest = resource.rest.find { |rest| rest.mode == 'server' }
        assert server_rest.present?, 'CapabilityStatement is missing a `rest` entry with `mode` set to `server`.'

        subscription_resource = server_rest.resource.find { |entry| entry.type == 'Subscription' }
        assert subscription_resource.present?,
               'CapabilityStatement is missing a `Subscription` resource entry in its server-mode `rest` section.'

        supported_interactions = subscription_resource.interaction.map(&:code)

        missing_interactions = REQUIRED_INTERACTIONS - supported_interactions

        assert missing_interactions.empty?, "Missing: #{missing_interactions.join(', ')}"
      end
    end
  end
end
