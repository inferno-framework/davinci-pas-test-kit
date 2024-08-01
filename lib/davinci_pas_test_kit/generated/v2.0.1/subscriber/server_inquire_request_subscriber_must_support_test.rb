require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireRequestSubscriberMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Subscriber Patient are observed across all instances submitted'
      description %(
        
        **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test. Errors encountered will be treated as a skip instead of a failure.

        PAS server systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        requests, including instances of the PAS Subscriber Patient Profile.
        This test checks all identified instances of the PAS Subscriber Patient
        Profile on requests sent to the server to ensure that the following
        must support elements are observed:

        * Patient.address
        * Patient.address.city
        * Patient.address.country
        * Patient.address.district
        * Patient.address.line
        * Patient.address.period
        * Patient.address.postalCode
        * Patient.address.state
        * Patient.birthDate
        * Patient.communication
        * Patient.communication.language
        * Patient.extension:birthsex
        * Patient.extension:ethnicity
        * Patient.extension:race
        * Patient.gender
        * Patient.identifier
        * Patient.identifier.system
        * Patient.identifier.value
        * Patient.name
        * Patient.name.family
        * Patient.name.given
        * Patient.name.prefix
        * Patient.name.suffix
        * Patient.telecom
        * Patient.telecom.system
        * Patient.telecom.use
        * Patient.telecom.value
      )

      id :pas_server_inquire_request_v201_subscriber_must_support_test

      def resource_type
        'Patient'
      end

      def user_input_validation
        true
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        # The scratch key in MS test should be the same as the scratch key in the validation test for a given profile.
        scratch[:inquire_request_resources] ||= {}
      end

      def resources_of_interest
        collection = tagged_resources(INQUIRE_TAG).presence || all_scratch_resources
        collection.select { |res| res.resourceType == resource_type }
      end

      run do
        perform_must_support_test(resources_of_interest)
        validate_must_support(user_input_validation)
      end
    end
  end
end
