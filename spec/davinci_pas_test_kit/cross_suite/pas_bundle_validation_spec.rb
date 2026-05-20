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

  describe 'US Core profile fallback' do
    let(:test_instance) do
      Class.new do
        include DaVinciPASTestKit::PasBundleValidation

        def messages
          @messages ||= []
        end

        def resource_is_valid?(**)
          true
        end
      end.new
    end

    def us_core_profile_url(profile_id)
      "#{described_class::US_CORE_PROFILE_BASE}/#{profile_id}|#{described_class::US_CORE_VERSION}"
    end

    def us_core_unversioned_profile_url(profile_id)
      "#{described_class::US_CORE_PROFILE_BASE}/#{profile_id}"
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

    def reference_extension(url, reference)
      FHIR::Extension.new(
        url:,
        valueReference: FHIR::Reference.new(reference:)
      )
    end

    def claim_with_encounter_reference(reference)
      FHIR::Claim.new(
        id: 'claim-1',
        extension: [
          reference_extension(described_class::CLAIM_ENCOUNTER_EXTENSION_URL, reference)
        ]
      )
    end

    def claim_with_requested_service_reference(reference)
      FHIR::Claim.new(
        id: 'claim-1',
        item: [
          FHIR::Claim::Item.new(
            extension: [
              reference_extension(
                'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-requestedService',
                reference
              )
            ]
          )
        ]
      )
    end

    describe '#us_core_profile_fallback_enabled?' do
      it 'returns true for PAS v2.2.x versions' do
        expect(test_instance.send(:us_core_profile_fallback_enabled?, '2.2.0')).to be(true)
        expect(test_instance.send(:us_core_profile_fallback_enabled?, '2.2.1')).to be(true)
      end

      it 'returns false for PAS v2.0.1' do
        expect(test_instance.send(:us_core_profile_fallback_enabled?, '2.0.1')).to be(false)
      end
    end

    describe '#find_profile_url' do
      it 'treats compound submit request types as submit operations' do
        expect(test_instance.send(:find_profile_url, 'submit_request')['Claim'])
          .to eq(DaVinciPASTestKit::PASConstants::CLAIM_PROFILE)
        expect(test_instance.send(:find_profile_url, 'submit_response')['ClaimResponse'])
          .to eq(DaVinciPASTestKit::PASConstants::CLAIM_RESPONSE_PROFILE)
      end

      it 'treats compound inquire request types as inquiry operations' do
        expect(test_instance.send(:find_profile_url, 'inquire_request')['Claim'])
          .to eq(DaVinciPASTestKit::PASConstants::CLAIM_INQUIRY_PROFILE)
        expect(test_instance.send(:find_profile_url, 'inquire_response')['ClaimResponse'])
          .to eq(DaVinciPASTestKit::PASConstants::CLAIM_INQUIRY_RESPONSE_PROFILE)
      end
    end

    describe '#us_core_condition_profile_ids' do
      it 'uses the encounter diagnosis profile for matching encounter-diagnosis category' do
        condition = FHIR::Condition.new(
          category: [codeable_concept(described_class::TERMINOLOGY_CONDITION_CATEGORY_SYSTEM, 'encounter-diagnosis')]
        )

        expect(test_instance.send(:us_core_condition_profile_ids, condition))
          .to eq([described_class::US_CORE_CONDITION_ENCOUNTER_DIAGNOSIS_PROFILE_ID])
      end

      it 'uses the problems and health concerns profile for problem-list-item category' do
        condition = FHIR::Condition.new(
          category: [codeable_concept(described_class::TERMINOLOGY_CONDITION_CATEGORY_SYSTEM, 'problem-list-item')]
        )

        expect(test_instance.send(:us_core_condition_profile_ids, condition))
          .to eq([described_class::US_CORE_CONDITION_PROBLEMS_HEALTH_CONCERNS_PROFILE_ID])
      end

      it 'uses the problems and health concerns profile when no category is present' do
        expect(test_instance.send(:us_core_condition_profile_ids, FHIR::Condition.new))
          .to eq([described_class::US_CORE_CONDITION_PROBLEMS_HEALTH_CONCERNS_PROFILE_ID])
      end

      it 'does not use the encounter diagnosis profile when the category system differs' do
        condition = FHIR::Condition.new(
          category: [codeable_concept('http://example.com/condition-category', 'encounter-diagnosis')]
        )

        expect(test_instance.send(:us_core_condition_profile_ids, condition))
          .to eq([described_class::US_CORE_CONDITION_PROBLEMS_HEALTH_CONCERNS_PROFILE_ID])
      end
    end

    describe '#us_core_diagnostic_report_profile_ids' do
      it 'uses the lab profile for matching LAB category' do
        report = FHIR::DiagnosticReport.new(
          category: [codeable_concept(described_class::DIAGNOSTIC_REPORT_CATEGORY_SYSTEM, 'LAB')]
        )

        expect(test_instance.send(:us_core_diagnostic_report_profile_ids, report))
          .to eq([described_class::US_CORE_DIAGNOSTIC_REPORT_LAB_PROFILE_ID])
      end

      it 'uses the note profile for non-LAB category' do
        report = FHIR::DiagnosticReport.new(
          category: [codeable_concept(described_class::DIAGNOSTIC_REPORT_CATEGORY_SYSTEM, 'RAD')]
        )

        expect(test_instance.send(:us_core_diagnostic_report_profile_ids, report))
          .to eq([described_class::US_CORE_DIAGNOSTIC_REPORT_NOTE_PROFILE_ID])
      end

      it 'does not use the lab profile when the category system differs' do
        report = FHIR::DiagnosticReport.new(
          category: [codeable_concept('http://example.com/report-category', 'LAB')]
        )

        expect(test_instance.send(:us_core_diagnostic_report_profile_ids, report))
          .to eq([described_class::US_CORE_DIAGNOSTIC_REPORT_NOTE_PROFILE_ID])
      end
    end

    describe '#us_core_observation_profile_ids' do
      it 'returns only the code-specific profile for matching LOINC code 8867-4' do
        observation = FHIR::Observation.new(
          code: codeable_concept(described_class::LOINC_SYSTEM, '8867-4'),
          category: [codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'laboratory')]
        )

        expect(test_instance.send(:us_core_observation_profile_ids, observation))
          .to eq(['us-core-heart-rate'])
      end

      it 'uses laboratory and simple observation profiles when no code-specific profile matches' do
        observation = FHIR::Observation.new(
          code: codeable_concept(described_class::LOINC_SYSTEM, '99999-9'),
          category: [codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'laboratory')]
        )

        expect(test_instance.send(:us_core_observation_profile_ids, observation))
          .to eq([
                   described_class::US_CORE_OBSERVATION_LAB_PROFILE_ID,
                   described_class::US_CORE_SIMPLE_OBSERVATION_PROFILE_ID
                 ])
      end

      it 'includes smoking status for social-history category' do
        observation = FHIR::Observation.new(
          category: [codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'social-history')]
        )

        expect(test_instance.send(:us_core_observation_profile_ids, observation))
          .to eq([
                   described_class::US_CORE_SMOKING_STATUS_PROFILE_ID,
                   described_class::US_CORE_OBSERVATION_CLINICAL_RESULT_PROFILE_ID,
                   described_class::US_CORE_SIMPLE_OBSERVATION_PROFILE_ID
                 ])
      end

      it 'uses clinical result and simple observation profiles when no category matches' do
        observation = FHIR::Observation.new(
          category: [codeable_concept('http://example.com/observation-category', 'laboratory')]
        )

        expect(test_instance.send(:us_core_observation_profile_ids, observation))
          .to eq([
                   described_class::US_CORE_OBSERVATION_CLINICAL_RESULT_PROFILE_ID,
                   described_class::US_CORE_SIMPLE_OBSERVATION_PROFILE_ID
                 ])
      end

      it 'includes simple observation as the final catch-all for category-based fallback' do
        observation = FHIR::Observation.new(
          category: [codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'survey')]
        )

        expect(test_instance.send(:us_core_observation_profile_ids, observation).last)
          .to eq(described_class::US_CORE_SIMPLE_OBSERVATION_PROFILE_ID)
      end
    end

    describe '#add_us_core_profiles_to_unprofiled_entries' do
      it 'does not apply when the entry already has PAS profiles assigned' do
        document_reference = FHIR::DocumentReference.new(id: 'doc-1')
        entry = bundle_entry(document_reference, 'urn:uuid:doc-1')
        pas_profile = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-documentreference'

        test_instance.add_resource_target_profile_to_map('urn:uuid:doc-1', document_reference, pas_profile)
        test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.2.0')

        expect(test_instance.bundle_resources_target_profile_map['urn:uuid:doc-1'][:profile_urls])
          .to contain_exactly(pas_profile)
      end

      it 'does not apply when the PAS version is 2.0.1' do
        patient = FHIR::Patient.new(id: 'patient-1')
        entry = bundle_entry(patient, 'urn:uuid:patient-1')

        test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.0.1')

        expect(test_instance.bundle_resources_target_profile_map).to_not have_key('urn:uuid:patient-1')
      end

      it 'applies the correct US Core profile for Patient' do
        patient = FHIR::Patient.new(id: 'patient-1')
        entry = bundle_entry(patient, 'urn:uuid:patient-1')

        test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.2.0')

        expect(test_instance.bundle_resources_target_profile_map['urn:uuid:patient-1'][:profile_urls])
          .to contain_exactly(us_core_profile_url('us-core-patient'))
      end

      it 'applies the base R4 sentinel for NutritionOrder' do
        nutrition_order = FHIR::NutritionOrder.new(id: 'nutrition-order-1')
        entry = bundle_entry(nutrition_order, 'urn:uuid:nutrition-order-1')

        test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.2.0')

        expect(test_instance.bundle_resources_target_profile_map['urn:uuid:nutrition-order-1'][:profile_urls])
          .to contain_exactly(described_class::BASE_R4_PROFILE)
      end
    end

    it 'uses US Core fallback rather than declared meta.profile for entries not reached by PAS traversal' do
      claim = FHIR::Claim.new(id: 'claim-1')
      custom_profile = 'http://example.com/fhir/StructureDefinition/custom-documentreference'
      document_reference = FHIR::DocumentReference.new(
        id: 'doc-1',
        meta: FHIR::Meta.new(profile: [custom_profile])
      )
      bundle = FHIR::Bundle.new(
        entry: [
          bundle_entry(claim, 'http://example.com/fhir/Claim/claim-1'),
          bundle_entry(document_reference, 'http://example.com/fhir/DocumentReference/doc-1')
        ]
      )

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.0',
        'submit'
      )

      expect(
        test_instance
          .bundle_resources_target_profile_map['http://example.com/fhir/DocumentReference/doc-1'][:profile_urls]
      ).to contain_exactly(us_core_profile_url('us-core-documentreference'))
    end

    describe '#codeable_concept_has_code?' do
      it 'matches when the coding system matches' do
        concept = codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'laboratory')

        expect(test_instance.send(:codeable_concept_has_code?, concept, 'laboratory',
                                  system: described_class::OBSERVATION_CATEGORY_SYSTEM)).to be(true)
      end

      it 'does not match when the coding system is blank' do
        concept = codeable_concept(nil, 'laboratory')

        expect(test_instance.send(:codeable_concept_has_code?, concept, 'laboratory',
                                  system: described_class::OBSERVATION_CATEGORY_SYSTEM)).to be(false)
      end

      it 'does not match when the coding system differs' do
        concept = codeable_concept('http://example.com/observation-category', 'laboratory')

        expect(test_instance.send(:codeable_concept_has_code?, concept, 'laboratory',
                                  system: described_class::OBSERVATION_CATEGORY_SYSTEM)).to be(false)
      end
    end

    it 'resolves versioned PAS reference target profiles against unversioned metadata keys' do
      claim = claim_with_encounter_reference('Encounter/encounter-1')
      encounter = FHIR::Encounter.new(id: 'encounter-1')
      bundle = FHIR::Bundle.new(
        entry: [
          bundle_entry(claim, 'http://example.com/fhir/Claim/claim-1'),
          bundle_entry(encounter, 'http://example.com/fhir/Encounter/encounter-1')
        ]
      )

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

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

    it 'traverses Claim requestedService extensions to the PAS ServiceRequest profile before US Core fallback' do
      claim = claim_with_requested_service_reference('ServiceRequest/service-request-1')
      service_request = FHIR::ServiceRequest.new(id: 'service-request-1')
      bundle = FHIR::Bundle.new(
        entry: [
          bundle_entry(claim, 'http://example.com/fhir/Claim/claim-1'),
          bundle_entry(service_request, 'http://example.com/fhir/ServiceRequest/service-request-1')
        ]
      )

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.0',
        'submit'
      )

      expect(
        test_instance
          .bundle_resources_target_profile_map['http://example.com/fhir/ServiceRequest/service-request-1'][:profile_urls]
      ).to contain_exactly('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-servicerequest')
    end

    it 'traverses Claim requestedService extensions for submit_request server validation' do
      claim = claim_with_requested_service_reference('ServiceRequest/service-request-1')
      service_request = FHIR::ServiceRequest.new(id: 'service-request-1')
      bundle = FHIR::Bundle.new(
        entry: [
          bundle_entry(claim, 'http://example.com/fhir/Claim/claim-1'),
          bundle_entry(service_request, 'http://example.com/fhir/ServiceRequest/service-request-1')
        ]
      )

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.0',
        'submit_request'
      )

      expect(
        test_instance.bundle_resources_target_profile_map['http://example.com/fhir/Claim/claim-1'][:profile_urls]
      ).to include(DaVinciPASTestKit::PASConstants::CLAIM_PROFILE)
      expect(
        test_instance
          .bundle_resources_target_profile_map['http://example.com/fhir/ServiceRequest/service-request-1'][:profile_urls]
      ).to contain_exactly('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-servicerequest')
    end

    it 'uses the base R4 sentinel to validate without a profile URL' do
      nutrition_order = FHIR::NutritionOrder.new(id: 'nutrition-order-1')

      test_instance.add_resource_target_profile_to_map(
        'urn:uuid:nutrition-order-1',
        nutrition_order,
        described_class::BASE_R4_PROFILE
      )

      allow(test_instance).to receive(:resource_is_valid?).with(resource: nutrition_order).and_return(true)

      test_instance.validate_bundle_entries_against_profiles('2.2.0')

      expect(test_instance).to have_received(:resource_is_valid?).with(resource: nutrition_order)
      expect(test_instance.validation_error_messages).to be_empty
    end

    it 'applies IG-specific versions only when needed for validation' do
      versioned_profile = us_core_profile_url('us-core-documentreference')
      unversioned_us_core_profile = us_core_unversioned_profile_url('us-core-documentreference')
      base_profile = 'http://hl7.org/fhir/StructureDefinition/DocumentReference'
      pas_profile = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-documentreference'

      expect(
        test_instance.send(
          :profile_url_for_validation,
          versioned_profile,
          base_profile,
          '2.2.0'
        )
      ).to eq(versioned_profile)
      expect(
        test_instance.send(:profile_url_for_validation, unversioned_us_core_profile, base_profile, '2.2.0')
      ).to eq(versioned_profile)
      expect(
        test_instance.send(:profile_url_for_validation, unversioned_us_core_profile, base_profile, '2.0.1')
      ).to eq(versioned_profile)
      expect(
        test_instance.send(:profile_url_for_validation, pas_profile, base_profile, '2.2.0')
      ).to eq("#{pas_profile}|2.2.0")
      expect(
        test_instance.send(:profile_url_for_validation, base_profile, base_profile, '2.2.0')
      ).to eq(base_profile)
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
