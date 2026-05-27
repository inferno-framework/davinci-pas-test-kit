RSpec.describe DaVinciPASTestKit::PasBundleValidation, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v201' }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:pa_request_valid_bundle) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
  end

  def entity_result_messages(runnable)
    results_repo.current_results_for_test_session_and_runnables(test_session.id, [runnable])
      .first
      .messages
  end

  describe '#validate_pa_request_payload_structure' do
    let(:test) do
      Class.new(Inferno::Test) do
        include DaVinciPASTestKit::PasBundleValidation

        fhir_client { url :server_endpoint }
        input :server_endpoint, :pa_request_payload

        def resource_type
          'Bundle'
        end

        run do
          bundle = FHIR.from_contents(pa_request_payload)
          assert_resource_type(:bundle, resource: bundle)
          validate_pa_request_payload_structure(bundle, 'submit')
          validation_error_messages.each do |msg|
            messages << { type: 'error', message: msg }
          end
          msg = 'Bundle(s) provided and/or entry resources are not conformant. Check messages for issues found.'
          skip_if validation_error_messages.present?, msg
        end
      end
    end

    before do
      Inferno::Repositories::Tests.new.insert(test)
    end

    context 'when a valid PA request bundle is provided' do
      it 'validates the PA request bundle' do
        result = run(test, server_endpoint:, pa_request_payload: pa_request_valid_bundle)
        expect(result.result).to eq('pass')
      end
    end

    context 'when an invalid PA request bundle is provided' do
      it 'fails if the payload is not a Bundle resource' do
        pa_request_payload =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'pas_claim.json'
                    ))

        result = run(test, server_endpoint:, pa_request_payload:)
        expect(result.result).to eq('fail')
        expect(result.result_message).to match(/Unexpected resource type: expected Bundle, but received Claim/)
      end

      it 'skips if the first entry is not a Claim resource' do
        pa_request_payload =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'nonconformant_pas_bundle_v110.json'
                    ))

        result = run(test, server_endpoint:, pa_request_payload:)
        expect(result.result).to eq('skip')
        expect(result.result_message).to match(/Check messages for issues found/)
        messages = entity_result_messages(test)
        expect(messages.size).to eq(1)
        expect(messages[0].message).to match(/The first bundle entry must be a Claim/)
      end

      it 'skips when referenced resource is missing from the bundle' do
        pa_request_payload =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'missing_referenced_resource_request_bundle.json'
                    ))

        result = run(test, server_endpoint:, pa_request_payload:)
        expect(result.result).to eq('skip')
        expect(result.result_message).to match(/Check messages for issues found/)
        messages = entity_result_messages(test)
        expect(messages.size).to eq(1)
        expect(messages[0].message).to match(/SHALL appear exactly once in the Bundle, but found 0/)
      end
    end
  end

  describe '#validate_pa_response_body_structure' do
    let(:test) do
      Class.new(Inferno::Test) do
        include DaVinciPASTestKit::PasBundleValidation

        fhir_client { url :server_endpoint }
        input :server_endpoint, :response_body, :request_bundle

        def resource_type
          'Bundle'
        end

        run do
          fhir_response = FHIR.from_contents(response_body)
          validate_pa_response_body_structure(fhir_response, request_bundle)
          validation_error_messages.each do |msg|
            messages << { type: 'error', message: msg }
          end
          msg = 'Bundle response returned and/or entry resources are not conformant. Check messages for issues found.'
          assert validation_error_messages.blank?, msg
        end
      end
    end

    before do
      Inferno::Repositories::Tests.new.insert(test)
    end

    context 'when a valid PA response bundle is provided' do
      it 'validates the PA response bundle' do
        pa_response_bundle =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'
                    ))

        result = run(test, server_endpoint:, response_body: pa_response_bundle, request_bundle: pa_request_valid_bundle)
        expect(result.result).to eq('pass')
      end
    end

    context 'when an invalid PA response bundle is provided' do
      it 'fails if the first entry is not a ClaimResponse' do
        pa_response_bundle =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'invalid_first_entry_response_bundle.json'
                    ))

        result = run(test, server_endpoint:, response_body: pa_response_bundle, request_bundle: pa_request_valid_bundle)
        expect(result.result).to eq('fail')
        expect(result.result_message).to match(/Check messages for issues found/)
        messages = entity_result_messages(test)
        expect(messages.size).to eq(1)
        expect(messages[0].message).to match(/The first bundle entry must be a ClaimResponse/)
      end

      it 'fails when referenced resource is missing from the bundle' do
        pa_response_bundle =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'missing_referenced_resource_response_bundle.json'
                    ))

        result = run(test, server_endpoint:, response_body: pa_response_bundle, request_bundle: pa_request_valid_bundle)
        expect(result.result).to eq('fail')
        expect(result.result_message).to match(/Check messages for issues found/)
        messages = entity_result_messages(test)
        expect(messages.size).to eq(2)
        expect(messages[0].message).to match(/SHALL appear exactly once in the Bundle, but found 0/)
        expect(messages[1].message).to match(/SHALL appear exactly once in the Bundle, but found 0/)
      end
    end
  end

  describe '#validate_pas_bundle_json for v2.2.0' do
    let(:test) do
      Class.new(Inferno::Test) do
        include DaVinciPASTestKit::PasBundleValidation

        fhir_client { url :server_endpoint }
        input :server_endpoint, :response_json

        run do
          profile_url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-response-bundle'
          validate_pas_bundle_json(
            response_json,
            profile_url,
            '2.2.0',
            'inquire',
            'response_bundle'
          )
        end
      end
    end

    before do
      Inferno::Repositories::Tests.new.insert(test)
      allow_any_instance_of(test).to receive(:validate_resources_conformance_against_profile).and_return(nil)
    end

    context 'when a valid Parameters response is provided' do
      it 'validates the Parameters with Bundle inside' do
        bundle_json = File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
        bundle = FHIR.from_contents(bundle_json)

        # Wrap Bundle in Parameters
        parameters = FHIR::Parameters.new
        parameters.parameter << FHIR::Parameters::Parameter.new(
          name: 'return',
          resource: bundle
        )

        result = run(test, server_endpoint:, response_json: parameters.to_json)
        expect(result.result).to eq('pass')
      end

      it 'validates Parameters with multiple Bundles (multiple return parameter entries)' do
        bundle_json = File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))
        bundle1 = FHIR.from_contents(bundle_json)
        bundle2 = FHIR.from_contents(bundle_json)

        # Create Parameters with multiple return parameter entries
        parameters = FHIR::Parameters.new
        parameters.parameter << FHIR::Parameters::Parameter.new(
          name: 'return',
          resource: bundle1
        )
        parameters.parameter << FHIR::Parameters::Parameter.new(
          name: 'return',
          resource: bundle2
        )

        result = run(test, server_endpoint:, response_json: parameters.to_json)
        expect(result.result).to eq('pass')
      end
    end

    context 'when invalid response is provided for v2.2.0' do
      it 'fails with error if Bundle provided instead of Parameters' do
        bundle_json = File.read(File.join(__dir__, '../..', 'fixtures', 'valid_pa_response_bundle.json'))

        result = run(test, server_endpoint:, response_json: bundle_json)
        expect(result.result).to eq('fail')
        expect(result.result_message).to match(/not conformant/)
      end

      it 'passes if Parameters is empty (no return parameters)' do
        parameters = FHIR::Parameters.new
        # No parameters added - valid per v2.2.0 (no matching results)

        result = run(test, server_endpoint:, response_json: parameters.to_json)
        expect(result.result).to eq('pass')
      end
    end
  end

  describe '#reject_entry_resource_issues' do
    let(:validator_issue_class) { Inferno::DSL::FHIRResourceValidation::ValidatorIssue }
    let(:test_instance) do
      Class.new { include DaVinciPASTestKit::PasBundleValidation }.new
    end

    def make_issue(location:, level: 'WARNING', message: 'test message', filtered: false)
      validator_issue_class.new(
        raw_issue: { 'location' => location, 'level' => level, 'message' => message },
        target: {},
        filtered:
      )
    end

    it 'keeps bundle-structural issues and rejects Bundle.entry[N].resource issues' do
      # Structural slicing hints — location at Bundle.entry[N] with no .resource segment
      first_entry_slicing_hint = make_issue(
        location: 'Bundle.entry[0]',
        level: 'INFORMATION',
        message: 'This element does not match any known slice defined in the profile ' \
                 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle|2.0.1'
      )
      third_entry_slicing_hint = make_issue(
        location: 'Bundle.entry[2]',
        level: 'INFORMATION',
        message: 'This element does not match any known slice defined in the profile ' \
                 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle|2.0.1'
      )
      fourth_entry_slicing_hint = make_issue(
        location: 'Bundle.entry[3]',
        level: 'INFORMATION',
        message: 'This element does not match any known slice defined in the profile ' \
                 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle|2.0.1'
      )
      # A bundle-level error (e.g. missing required field on the Bundle itself)
      bundle_error = make_issue(
        location: 'Bundle.timestamp',
        level: 'ERROR',
        message: 'Bundle.timestamp: minimum required = 1, but only found 0'
      )

      # Entry-resource issues — location at/below Bundle.entry[N].resource
      org_x12_warning = make_issue(
        location: 'Bundle.entry[0].resource/*Organization/UMOExample*/.type[0]',
        level: 'WARNING',
        message: "A definition for CodeSystem 'https://codesystem.x12.org/005010/98' could not be found"
      )
      claim_response_xhtml_error = make_issue(
        location: 'Bundle.entry[1].resource/*ClaimResponse/ReferralAuthorizationResponseExample*/.text.div',
        level: 'ERROR',
        message: "Hyperlink '#Patient_SubscriberExample' at 'div/p/a' for " \
                 "'See above (Patient/SubscriberExample)' does not resolve"
      )
      claim_response_url_warning = make_issue(
        location: 'Bundle.entry[1].resource/*ClaimResponse/ReferralAuthorizationResponseExample*/' \
                  'identifier[0].system',
        level: 'WARNING',
        message: 'No definition could be found for URL value ' \
                 "'https://prior-auth.davinci.hl7.org/PATIENT_EVENT_TRACE_NUMBER'"
      )
      patient_valueset_warning = make_issue(
        location: 'Bundle.entry[3].resource/*Patient/SubscriberExample*/' \
                  'extension[0].value.ofType(CodeableConcept)',
        level: 'WARNING',
        message: "ValueSet 'https://valueset.x12.org/x217/005010/request/2010C/INS/1/08/00/584' not found"
      )

      issues = [
        first_entry_slicing_hint, org_x12_warning, claim_response_xhtml_error,
        claim_response_url_warning, third_entry_slicing_hint, patient_valueset_warning,
        fourth_entry_slicing_hint, bundle_error
      ]

      result = test_instance.send(:reject_entry_resource_issues, issues)

      expect(result).to contain_exactly(first_entry_slicing_hint, third_entry_slicing_hint,
                                        fourth_entry_slicing_hint, bundle_error)
    end

    it 'rejects issues pre-marked as filtered regardless of location' do
      # A structural-location issue (would normally be kept) but marked filtered by the validator
      filtered_structural = make_issue(
        location: 'Bundle.entry[0]',
        level: 'INFORMATION',
        message: 'This element does not match any known slice defined in the profile',
        filtered: true
      )
      # An entry-resource issue also marked filtered — rejected both by flag and by location
      filtered_entry_resource = make_issue(
        location: 'Bundle.entry[2].resource/*Organization/InsurerExample*/.type[0].coding[0]',
        level: 'WARNING',
        message: "A definition for CodeSystem 'https://codesystem.x12.org/005010/98' " \
                 'could not be found, so the code cannot be validated',
        filtered: true
      )
      # An unfiltered structural issue — should survive
      unfiltered_structural = make_issue(
        location: 'Bundle.entry[3]',
        level: 'INFORMATION',
        message: 'This element does not match any known slice defined in the profile'
      )

      result = test_instance.send(:reject_entry_resource_issues,
                                  [filtered_structural, filtered_entry_resource, unfiltered_structural])

      expect(result).to contain_exactly(unfiltered_structural)
    end

    it 'returns an empty array when given an empty list' do
      expect(test_instance.send(:reject_entry_resource_issues, [])).to be_empty
    end
  end

  describe '#determine_claim_submit_profile_url' do
    let(:test_instance) do
      Class.new { include DaVinciPASTestKit::PasBundleValidation }.new
    end

    let(:base_claim_url) { 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim' }
    let(:claim_update_url) { DaVinciPASTestKit::PASConstants::CLAIM_PROFILE }

    context 'when version is 2.0.1' do
      it 'returns profile-claim-update regardless of Claim.related' do
        claim = FHIR::Claim.new
        expect(test_instance.send(:determine_claim_submit_profile_url, '2.0.1', claim)).to eq(claim_update_url)
      end
    end

    context 'when version is 2.2.0' do
      it 'returns profile-claim when Claim.related is absent' do
        claim = FHIR::Claim.new
        expect(test_instance.send(:determine_claim_submit_profile_url, '2.2.0', claim)).to eq(base_claim_url)
      end

      it 'returns profile-claim-update when Claim.related is present' do
        claim = FHIR::Claim.new(related: [{ relationship: { coding: [{ code: 'prior' }] } }])
        expect(test_instance.send(:determine_claim_submit_profile_url, '2.2.0', claim)).to eq(claim_update_url)
      end
    end
  end
end
