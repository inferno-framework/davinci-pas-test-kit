require_relative '../../../must_support_test'
require_relative '../../../generator/group_metadata'
require_relative '../../../tags'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireResponseTaskMustSupportTest < Inferno::Test
      include DaVinciPASTestKit::MustSupportTest

      title 'All must support elements for Profile PAS Task are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Task Profile.
        This test checks all identified instances of the PAS Task
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * Task.code
        * Task.for
        * Task.identifier
        * Task.input
        * Task.intent
        * Task.owner
        * Task.owner.identifier
        * Task.reasonCode.coding.code
        * Task.reasonReference
        * Task.requester
        * Task.requester.identifier
        * Task.restriction.period
        * Task.status
        * Task.statusReason
      )

      id :pas_server_inquire_response_v201_task_must_support_test

      def resource_type
        'Task'
      end

      def user_input_validation
        false
      end

      def self.metadata
        @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        # The scratch key in MS test should be the same as the scratch key in the validation test for a given profile.
        scratch[:inquire_response_resources] ||= {}
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
