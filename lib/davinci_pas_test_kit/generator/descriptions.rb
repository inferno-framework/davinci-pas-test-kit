require_relative '../cross_suite/pas_constants'

module DaVinciPASTestKit
  class Generator
    module Descriptions
      class << self
        def profile_links_list(required_groups, request_groups: nil)
          <<~DESCRIPTION
            #{profile_links(required_groups).join("\n")}
            #{request_profile_links_list(request_groups) if request_groups.present?}
          DESCRIPTION
        end

        def request_profile_links_list(request_groups)
          <<~DESCRIPTION
            - At least one of the following request profiles
            #{profile_links(request_groups, prefix: '  ').join("\n")}
          DESCRIPTION
        end

        def profile_links(groups, prefix: '')
          groups.map do |group_metadata|
            "#{prefix}- [#{group_metadata.profile_name}](#{profile_url_to_link(group_metadata.profile_url)})"
          end
        end

        def bundle_profile_link(operation, type)
          "[#{PASConstants.bundle_profile_name_for_operation_and_type(operation, type)}]" \
            "(#{profile_url_to_link(PASConstants.bundle_profile_url_for_operation_and_type(operation, type))})"
        end

        def profile_url_to_link(profile_url)
          "#{profile_url.gsub('http:', 'https:')
            .gsub('davinci-pas/', 'davinci-pas/STU2/') # TODO: update to support other ig versions
            .gsub('StructureDefinition/', 'StructureDefinition-')}.html"
        end

        def bundle_validation_test_description(operation, type)
          <<~DESCRIPTION
            #{"#{description_user_input_validation}\n" if type == 'request'}This test validates the conformity of the
            #{type == 'request' ? 'user input' : "server's response"} to the
            #{bundle_profile_link(operation, type)}
            profile#{type == 'request' ? ', ensuring subsequent tests can accurately simulate content.' : '.'}

            It also checks that other conformance requirements defined in the [PAS Formal
            Specification](https://hl7.org/fhir/us/davinci-pas/STU2/specification.html),
            such as the presence of all referenced instances within the bundle and the
            conformance of those instances to the appropriate profiles, are met.

            It verifies the presence of mandatory elements and that elements with
            required bindings contain appropriate values. CodeableConcept element
            bindings will fail if none of their codings have a code/system belonging
            to the bound ValueSet. Quantity, Coding, and code element bindings will
            fail if their code/system are not found in the valueset.

            Note that because X12 value sets are not public, elements bound to value
            sets containing X12 codes are not validated.

            **Limitations**

            Due to recognized errors in the PAS IG around extension context definitions,
            this test may not pass due to spurious errors of the form "The extension
            [extension url] is not allowed at this point". See [this
            issue](https://github.com/inferno-framework/davinci-pas-test-kit/issues/11)
            for additional details.
          DESCRIPTION
        end

        def description_user_input_validation
          <<~USER_INPUT_INTRO
            **USER INPUT VALIDATION**: This test validates input provided by the user instead of the system under test.
            Errors encountered will be treated as a skip instead of a failure.
          USER_INPUT_INTRO
        end
      end
    end
  end
end
