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

  describe 'US Core profile inference' do
    let(:test_instance) do
      Class.new do
        include DaVinciPASTestKit::PasBundleValidation

        def evaluate_fhirpath(**)
          []
        end
      end.new
    end

    def us_core_profile_url(profile_id)
      "#{described_class::US_CORE_PROFILE_BASE}/#{profile_id}|#{described_class::US_CORE_VERSION}"
    end

    def codeable_concept(system, code)
      FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system:,
            code:
          )
        ]
      )
    end

    def bundle_entry(resource, full_url)
      FHIR::Bundle::Entry.new(
        fullUrl: full_url,
        resource:
      )
    end

    it 'adds a US Core fallback profile for unprofiled v2.2 bundle entries without PAS profiles' do
      questionnaire_response = FHIR::QuestionnaireResponse.new(id: 'questionnaire-response-1')
      entry = bundle_entry(questionnaire_response, 'urn:uuid:questionnaire-response-1')
      bundle = FHIR::Bundle.new(entry: [entry])

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.0',
        'submit'
      )

      expect(test_instance.bundle_resources_target_profile_map['urn:uuid:questionnaire-response-1'][:profile_urls])
        .to contain_exactly(us_core_profile_url('us-core-questionnaireresponse'))
    end

    it 'does not add US Core fallback profiles for earlier PAS versions' do
      document_reference = FHIR::DocumentReference.new(id: 'doc-1')
      entry = bundle_entry(document_reference, 'urn:uuid:doc-1')
      bundle = FHIR::Bundle.new(entry: [entry])

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.0.1',
        'submit'
      )

      expect(test_instance.bundle_resources_target_profile_map).to_not have_key('urn:uuid:doc-1')
    end

    it 'does not add US Core fallback profiles for non-v2.2 versions with a v2.2 prefix' do
      document_reference = FHIR::DocumentReference.new(id: 'doc-1')
      entry = bundle_entry(document_reference, 'urn:uuid:doc-1')
      bundle = FHIR::Bundle.new(entry: [entry])

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.20.0',
        'submit'
      )

      expect(test_instance.bundle_resources_target_profile_map).to_not have_key('urn:uuid:doc-1')
    end

    it 'does not add a fallback when PAS inference already found a target profile' do
      document_reference = FHIR::DocumentReference.new(id: 'doc-1')
      entry = bundle_entry(document_reference, 'urn:uuid:doc-1')
      inferred_profile = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-documentreference'

      test_instance.add_resource_target_profile_to_map('urn:uuid:doc-1', document_reference, inferred_profile)
      test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.2.0')

      expect(test_instance.bundle_resources_target_profile_map['urn:uuid:doc-1'][:profile_urls])
        .to contain_exactly(inferred_profile)
    end

    it 'uses declared profiles before US Core fallback for PAS-profiled entries' do
      encounter = FHIR::Encounter.new(
        id: 'encounter-1',
        meta: {
          profile: ['http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter']
        }
      )
      entry = bundle_entry(encounter, 'urn:uuid:encounter-1')
      bundle = FHIR::Bundle.new(entry: [entry])

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.0',
        'submit'
      )

      expect(test_instance.bundle_resources_target_profile_map['urn:uuid:encounter-1'][:profile_urls])
        .to contain_exactly('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter')
    end

    it 'uses unique PAS profiles before US Core fallback for unprofiled PAS resources' do
      service_request = FHIR::ServiceRequest.new(id: 'service-request-1')
      entry = bundle_entry(service_request, 'urn:uuid:service-request-1')
      bundle = FHIR::Bundle.new(entry: [entry])

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.0',
        'submit'
      )

      expect(test_instance.bundle_resources_target_profile_map['urn:uuid:service-request-1'][:profile_urls])
        .to contain_exactly('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-servicerequest')
    end

    it 'resolves versioned PAS reference target profiles against unversioned metadata keys' do
      claim = FHIR::Claim.new(id: 'claim-1')
      encounter = FHIR::Encounter.new(id: 'encounter-1')
      bundle = FHIR::Bundle.new(
        entry: [
          bundle_entry(claim, 'http://example.com/fhir/Claim/claim-1'),
          bundle_entry(encounter, 'http://example.com/fhir/Encounter/encounter-1')
        ]
      )

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)
      allow(test_instance).to receive(:evaluate_fhirpath) do |path:, **|
        if path == 'Claim.extension.value[x]'
          [{ 'type' => 'Reference', 'element' => FHIR::Reference.new(reference: 'Encounter/encounter-1') }]
        else
          []
        end
      end

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.0',
        'submit'
      )

      expect(
        test_instance
          .bundle_resources_target_profile_map['http://example.com/fhir/Encounter/encounter-1'][:profile_urls]
      ).to contain_exactly('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter|2.2.0')
    end

    it 'selects the Condition US Core profile from category' do
      encounter_diagnosis = FHIR::Condition.new(
        category: [codeable_concept(nil, 'encounter-diagnosis')]
      )
      health_concern = FHIR::Condition.new(
        category: [codeable_concept('http://hl7.org/fhir/us/core/CodeSystem/condition-category', 'health-concern')]
      )
      uncategorized = FHIR::Condition.new

      expect(test_instance.send(:us_core_profile_urls_for_resource, encounter_diagnosis))
        .to contain_exactly(us_core_profile_url('us-core-condition-encounter-diagnosis'))
      expect(test_instance.send(:us_core_profile_urls_for_resource, health_concern))
        .to contain_exactly(us_core_profile_url('us-core-condition-problems-health-concerns'))
      expect(test_instance.send(:us_core_profile_urls_for_resource, uncategorized))
        .to contain_exactly(us_core_profile_url('us-core-condition-problems-health-concerns'))
    end

    it 'does not select the encounter diagnosis Condition profile for the right code on the wrong system' do
      condition = FHIR::Condition.new(
        category: [codeable_concept('http://example.com/condition-category', 'encounter-diagnosis')]
      )

      expect(test_instance.send(:us_core_profile_urls_for_resource, condition))
        .to contain_exactly(us_core_profile_url('us-core-condition-problems-health-concerns'))
    end

    it 'selects the DiagnosticReport US Core profile from category' do
      lab_report = FHIR::DiagnosticReport.new(
        category: [codeable_concept('http://terminology.hl7.org/CodeSystem/v2-0074', 'LAB')]
      )
      note_report = FHIR::DiagnosticReport.new(
        category: [codeable_concept('http://terminology.hl7.org/CodeSystem/v2-0074', 'RAD')]
      )

      expect(test_instance.send(:us_core_profile_urls_for_resource, lab_report))
        .to contain_exactly(us_core_profile_url('us-core-diagnosticreport-lab'))
      expect(test_instance.send(:us_core_profile_urls_for_resource, note_report))
        .to contain_exactly(us_core_profile_url('us-core-diagnosticreport-note'))
    end

    it 'does not select the lab DiagnosticReport profile for LAB from the wrong system' do
      lab_report = FHIR::DiagnosticReport.new(
        category: [codeable_concept('http://example.com/report-category', 'LAB')]
      )

      expect(test_instance.send(:us_core_profile_urls_for_resource, lab_report))
        .to contain_exactly(us_core_profile_url('us-core-diagnosticreport-note'))
    end

    it 'selects specific Observation profiles by code before category fallback profiles' do
      blood_pressure = FHIR::Observation.new(
        code: codeable_concept('http://loinc.org', '85354-9'),
        category: [codeable_concept('http://terminology.hl7.org/CodeSystem/observation-category', 'laboratory')]
      )

      expect(test_instance.send(:us_core_profile_urls_for_resource, blood_pressure))
        .to contain_exactly(us_core_profile_url('us-core-blood-pressure'))
    end

    it 'adds Observation category fallback profiles when no code-specific profile matches' do
      lab_observation = FHIR::Observation.new(
        code: codeable_concept('http://loinc.org', '99999-9'),
        category: [codeable_concept('http://terminology.hl7.org/CodeSystem/observation-category', 'laboratory')]
      )
      social_history_observation = FHIR::Observation.new(
        code: codeable_concept('http://loinc.org', '99999-8'),
        category: [codeable_concept('http://terminology.hl7.org/CodeSystem/observation-category', 'social-history')]
      )

      expect(test_instance.send(:us_core_profile_urls_for_resource, lab_observation))
        .to contain_exactly(
          us_core_profile_url('us-core-observation-lab'),
          us_core_profile_url('us-core-simple-observation')
        )
      expect(test_instance.send(:us_core_profile_urls_for_resource, social_history_observation))
        .to contain_exactly(
          us_core_profile_url('us-core-smokingstatus'),
          us_core_profile_url('us-core-observation-clinical-result'),
          us_core_profile_url('us-core-simple-observation')
        )
    end

    it 'does not select Observation category fallback profiles from the wrong category system' do
      lab_observation = FHIR::Observation.new(
        code: codeable_concept('http://loinc.org', '99999-9'),
        category: [codeable_concept('http://example.com/observation-category', 'laboratory')]
      )
      social_history_observation = FHIR::Observation.new(
        code: codeable_concept('http://loinc.org', '99999-8'),
        category: [codeable_concept('http://example.com/observation-category', 'social-history')]
      )

      expect(test_instance.send(:us_core_profile_urls_for_resource, lab_observation))
        .to contain_exactly(
          us_core_profile_url('us-core-observation-clinical-result'),
          us_core_profile_url('us-core-simple-observation')
        )
      expect(test_instance.send(:us_core_profile_urls_for_resource, social_history_observation))
        .to contain_exactly(
          us_core_profile_url('us-core-observation-clinical-result'),
          us_core_profile_url('us-core-simple-observation')
        )
    end

    it 'does not append the PAS IG version to versioned US Core profile URLs' do
      versioned_profile = us_core_profile_url('us-core-documentreference')

      expect(
        test_instance.send(
          :profile_url_for_validation,
          versioned_profile,
          'http://hl7.org/fhir/StructureDefinition/DocumentReference',
          '2.2.0'
        )
      ).to eq(versioned_profile)
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
end
