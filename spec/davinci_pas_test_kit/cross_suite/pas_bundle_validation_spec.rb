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
          messages.concat(validation_messages)
          msg = 'Bundle(s) provided and/or entry resources are not conformant. Check messages for issues found.'
          skip_if validation_messages.present?, msg
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
        expect(result.result_message).to include('Unexpected resource type: expected Bundle, but received Claim')
      end

      it 'skips if the first entry is not a Claim resource' do
        pa_request_payload =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'nonconformant_pas_bundle_v110.json'
                    ))

        result = run(test, server_endpoint:, pa_request_payload:)
        expect(result.result).to eq('skip')
        expect(result.result_message).to include('Check messages for issues found')
        messages = entity_result_messages(test)
        expect(messages.size).to eq(1)
        expect(messages[0].message).to include('The first bundle entry must be a Claim')
      end

      it 'skips when referenced resource is missing from the bundle' do
        pa_request_payload =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'missing_referenced_resource_request_bundle.json'
                    ))

        result = run(test, server_endpoint:, pa_request_payload:)
        expect(result.result).to eq('skip')
        expect(result.result_message).to include('Check messages for issues found')
        messages = entity_result_messages(test)
        expect(messages.size).to eq(1)
        expect(messages[0].message).to include('SHALL appear exactly once in the Bundle, but found 0')
      end
    end

    context 'when a multi-level Claim Update bundle is provided' do
      grandparent_urn = 'urn:uuid:11111111-1111-4111-8111-111111111111'
      parent_urn = 'urn:uuid:22222222-2222-4222-8222-222222222222'
      update_urn = 'urn:uuid:33333333-3333-4333-8333-333333333333'
      let(:missing_urn) { 'urn:uuid:99999999-9999-4999-8999-999999999999' }

      # An Update Claim (primary) that references its parent Claim, which is itself an update that in turn
      # references the grandparent. Per spec-65/66 the grandparent is deliberately omitted from the Bundle.
      define_method(:update_bundle) do |parent_extra = {}|
        parent_claim = { resourceType: 'Claim', id: 'claim-2', status: 'active', use: 'preauthorization',
                         related: [{ claim: { reference: grandparent_urn } }] }.merge(parent_extra)
        { resourceType: 'Bundle', type: 'collection',
          entry: [
            { fullUrl: update_urn,
              resource: { resourceType: 'Claim', id: 'claim-3', status: 'active', use: 'preauthorization',
                          related: [{ claim: { reference: parent_urn } }] } },
            { fullUrl: parent_urn, resource: parent_claim }
          ] }.to_json
      end

      it 'does not flag the deliberately-omitted grandparent Claim' do
        result = run(test, server_endpoint:, pa_request_payload: update_bundle)
        expect(result.result).to eq('pass')
      end

      it 'still flags a resource referenced only by the non-primary (parent) Claim' do
        result = run(test, server_endpoint:, pa_request_payload: update_bundle(provider: { reference: missing_urn }))
        expect(result.result).to eq('skip')
        messages = entity_result_messages(test)
        expect(messages.map(&:message).join).to include('SHALL appear exactly once in the Bundle, but found 0')
      end
    end
  end

  # perform_bundle_validation (used by the server suites, and now the client suites too) passes the compound
  # '<operation>_<type>' form, so 'submit_request' must get the $submit structure checks.
  describe '#validate_pa_request_payload_structure with the server submit_request type' do
    let(:validator) { Class.new { include DaVinciPASTestKit::PasBundleValidation }.new }
    let(:bundle) { FHIR.from_contents(pa_request_valid_bundle) }
    let(:claim) { bundle.entry.first.resource }

    def validation_message_text(request_type = 'submit_request')
      validator.validate_pa_request_payload_structure(bundle, request_type)
      validator.validation_messages.map { |m| m[:message] }.join("\n")
    end

    it 'reports no errors for a conformant $submit request Bundle' do
      validator.validate_pa_request_payload_structure(bundle, 'submit_request')

      expect(validator.validation_messages).to be_empty
    end

    it 'requires the first entry to be a Claim' do
      bundle.entry.rotate!

      expect(validation_message_text).to include('The first bundle entry must be a Claim')
    end

    it 'requires supportingInfo sequences to be unique' do
      claim.supportingInfo = [1, 1].map do |sequence|
        FHIR::Claim::SupportingInfo.new(sequence:, category: { text: 'info' })
      end

      expect(validation_message_text).to include('The sequence element for each supportingInfo entry SHALL be unique')
    end

    it 'requires entry fullUrls to be a url or urn:uuid' do
      bundle.entry.last.fullUrl = 'not-a-valid-full-url'

      expect(validation_message_text).to include('Bundle.entry.fullUrl values SHALL be a valid url')
    end

    it 'does not apply the $inquire structure checks' do
      claim.patient = nil

      expect(validation_message_text).to_not include('for inquiry operation must reference a patient')
      expect(validation_message_text('inquire_request')).to include('for inquiry operation must reference a patient')
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
          messages.concat(validation_messages)
          msg = 'Bundle and/or entry resources are not conformant. Check messages for issues found.'
          assert validation_messages.blank?, msg
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

    context 'when a response echoes a resource from the request' do
      let(:patient_full_url) { 'urn:uuid:patient' }
      let(:patient_id) { 'patient-1' }
      let(:patient_identifier_system) { 'http://example.com/mrn' }
      let(:patient_identifier) { '12345' }
      let(:request_bundle_with_patient) do
        {
          resourceType: 'Bundle',
          type: 'collection',
          entry: [
            {
              fullUrl: 'urn:uuid:claim',
              resource: {
                resourceType: 'Claim', id: 'claim', status: 'active', use: 'preauthorization'
              }
            },
            {
              fullUrl: patient_full_url,
              resource: {
                resourceType: 'Patient', id: patient_id,
                identifier: [{ system: patient_identifier_system, value: patient_identifier }]
              }
            }
          ]
        }.to_json
      end

      def response_bundle_with_echoed_patient(patient_full_url:, patient_id:, patient_identifier_system:,
                                              patient_identifier:)
        {
          resourceType: 'Bundle',
          type: 'collection',
          entry: [
            {
              fullUrl: 'urn:uuid:claim-response',
              resource: {
                resourceType: 'ClaimResponse', id: 'claim-response', status: 'active',
                use: 'preauthorization', outcome: 'complete'
              }
            },
            {
              fullUrl: patient_full_url,
              resource: {
                resourceType: 'Patient', id: patient_id,
                identifier: [{ system: patient_identifier_system, value: patient_identifier }]
              }
            }
          ]
        }.to_json
      end

      it 'validates an echoed resource with the same fullUrl, id, and identifiers' do
        result = run(
          test,
          server_endpoint:,
          response_body: response_bundle_with_echoed_patient(
            patient_full_url:, patient_id:, patient_identifier_system:, patient_identifier:
          ),
          request_bundle: request_bundle_with_patient
        )
        expect(result.result).to eq('pass')
      end

      it 'fails when an echoed resource has a different fullUrl' do
        result = run(
          test,
          server_endpoint:,
          response_body: response_bundle_with_echoed_patient(
            patient_full_url: 'urn:uuid:different-patient', patient_id:, patient_identifier_system:, patient_identifier:
          ),
          request_bundle: request_bundle_with_patient
        )
        expect(result.result).to eq('fail')
        expect(entity_result_messages(test).map(&:message).join)
          .to include('do not have the same fullUrl or identifiers')
      end

      it 'fails when an echoed resource has a different id' do
        result = run(
          test,
          server_endpoint:,
          response_body: response_bundle_with_echoed_patient(
            patient_full_url:, patient_id: 'different-patient', patient_identifier_system:, patient_identifier:
          ),
          request_bundle: request_bundle_with_patient
        )
        expect(result.result).to eq('fail')
        expect(entity_result_messages(test).map(&:message).join)
          .to include('do not have the same fullUrl or identifiers')
      end

      it 'fails when an echoed resource has a different identifier' do
        result = run(
          test,
          server_endpoint:,
          response_body: response_bundle_with_echoed_patient(
            patient_full_url:, patient_id:, patient_identifier_system:, patient_identifier: 'different'
          ),
          request_bundle: request_bundle_with_patient
        )
        expect(result.result).to eq('fail')
        expect(entity_result_messages(test).map(&:message).join)
          .to include('do not have the same fullUrl or identifiers')
      end

      it 'fails when an echoed resource has an identifier with a different system' do
        result = run(
          test,
          server_endpoint:,
          response_body: response_bundle_with_echoed_patient(
            patient_full_url:, patient_id:, patient_identifier_system: 'http://example.com/other-mrn',
            patient_identifier:
          ),
          request_bundle: request_bundle_with_patient
        )
        expect(result.result).to eq('fail')
        expect(entity_result_messages(test).map(&:message).join)
          .to include('do not have the same fullUrl or identifiers')
      end

      it 'does not flag unrelated resources that only share a resource type and blank ids' do
        request_bundle = {
          resourceType: 'Bundle', type: 'collection',
          entry: [
            { fullUrl: 'urn:uuid:claim', resource: {
              resourceType: 'Claim', id: 'claim', status: 'active', use: 'preauthorization'
            } },
            { fullUrl: 'urn:uuid:practitioner-request', resource: { resourceType: 'Practitioner' } }
          ]
        }.to_json
        response_bundle = {
          resourceType: 'Bundle', type: 'collection',
          entry: [
            { fullUrl: 'urn:uuid:claim-response', resource: {
              resourceType: 'ClaimResponse', id: 'claim-response', status: 'active',
              use: 'preauthorization', outcome: 'complete'
            } },
            { fullUrl: 'urn:uuid:practitioner-response', resource: { resourceType: 'Practitioner' } }
          ]
        }.to_json

        result = run(test, server_endpoint:, response_body: response_bundle, request_bundle:)
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
        expect(result.result_message).to include('Check messages for issues found')
        messages = entity_result_messages(test)
        expect(messages.size).to eq(1)
        expect(messages[0].message).to include('The first bundle entry must be a ClaimResponse')
      end

      it 'fails when referenced resource is missing from the bundle' do
        pa_response_bundle =
          File.read(File.join(
                      __dir__, '../..', 'fixtures', 'missing_referenced_resource_response_bundle.json'
                    ))

        result = run(test, server_endpoint:, response_body: pa_response_bundle, request_bundle: pa_request_valid_bundle)
        expect(result.result).to eq('fail')
        expect(result.result_message).to include('Check messages for issues found')
        messages = entity_result_messages(test)
        expect(messages.size).to eq(2)
        expect(messages[0].message).to include('SHALL appear exactly once in the Bundle, but found 0')
        expect(messages[1].message).to include('SHALL appear exactly once in the Bundle, but found 0')
      end
    end
  end

  describe '#perform_bundle_validation for a server $submit response' do
    let(:test_instance) do
      Class.new do
        include DaVinciPASTestKit::PasBundleValidation

        def messages
          @messages ||= []
        end
      end.new
    end

    let(:request_bundle) do
      FHIR.from_contents({
        resourceType: 'Bundle', type: 'collection',
        entry: [
          { fullUrl: 'urn:uuid:claim', resource: {
            resourceType: 'Claim', id: 'claim', status: 'active', use: 'preauthorization'
          } },
          { fullUrl: 'urn:uuid:patient', resource: {
            resourceType: 'Patient', id: 'patient-1',
            identifier: [{ system: 'http://example.com/mrn', value: '12345' }]
          } }
        ]
      }.to_json)
    end

    let(:response_bundle) do
      FHIR.from_contents({
        resourceType: 'Bundle', type: 'collection',
        entry: [
          { fullUrl: 'urn:uuid:claim-response', resource: {
            resourceType: 'ClaimResponse', id: 'claim-response', status: 'active',
            use: 'preauthorization', outcome: 'complete'
          } },
          { fullUrl: 'urn:uuid:different-patient', resource: {
            resourceType: 'Patient', id: 'patient-1',
            identifier: [{ system: 'http://example.com/mrn', value: '12345' }]
          } }
        ]
      }.to_json)
    end

    before do
      allow(test_instance).to receive(:validate_resources_conformance_against_profile)
    end

    it 'flags an echoed request resource with a different fullUrl' do
      test_instance.perform_bundle_validation(response_bundle, 'submit', 'response', 'v2.2.1', request_bundle)

      expect(test_instance.validation_messages.map { |m| m[:message] }.join)
        .to include('do not have the same fullUrl or identifiers')
    end
  end

  describe '#perform_bundle_validation validator selection' do
    let(:test_instance) do
      Class.new do
        include DaVinciPASTestKit::PasBundleValidation

        def evaluate_fhirpath(**)
          []
        end

        def messages
          @messages ||= []
        end

        def resource_is_valid?(**)
          true
        end
      end.new
    end

    let(:bundle) do
      FHIR.from_contents({
        resourceType: 'Bundle', type: 'collection',
        entry: [
          { fullUrl: 'urn:uuid:claim-response', resource: {
            resourceType: 'ClaimResponse', id: 'claim-response', status: 'active',
            use: 'preauthorization', outcome: 'complete'
          } }
        ]
      }.to_json)
    end

    before do
      allow(test_instance).to receive(:validate_pa_response_body_structure)
      allow(test_instance).to receive(:resource_is_valid?).and_call_original
    end

    it 'uses the default validator when none is specified' do
      test_instance.perform_bundle_validation(bundle, 'inquire', 'response', 'v2.2.1')

      expect(test_instance).to have_received(:resource_is_valid?).at_least(:once)
      expect(test_instance).to have_received(:resource_is_valid?).with(hash_including(validator: :default))
        .at_least(:once)
      expect(test_instance).to_not have_received(:resource_is_valid?)
        .with(hash_including(validator: :no_custom_extensions))
    end

    it 'uses the specified validator for every profile validation' do
      test_instance.perform_bundle_validation(bundle, 'inquire', 'response', 'v2.2.1',
                                              validator: :no_custom_extensions)

      expect(test_instance).to have_received(:resource_is_valid?).at_least(:once)
      expect(test_instance).to_not have_received(:resource_is_valid?).with(hash_including(validator: :default))
    end

    it 'does not carry the validator over to a later validation' do
      test_instance.perform_bundle_validation(bundle, 'inquire', 'response', 'v2.2.1',
                                              validator: :no_custom_extensions)
      test_instance.perform_bundle_validation(bundle, 'inquire', 'request', 'v2.2.1')

      expect(test_instance).to have_received(:resource_is_valid?).with(hash_including(validator: :default))
        .at_least(:once)
    end
  end

  describe '#perform_bundle_validation with echoed resources' do
    let(:test_instance) do
      Class.new do
        include DaVinciPASTestKit::PasBundleValidation

        def suite_options
          {}
        end

        def evaluate_fhirpath(**)
          []
        end

        def messages
          @messages ||= []
        end

        def resource_is_valid?(**)
          true
        end
      end.new
    end

    let(:custom_extension) { { url: 'http://example.org/fhir/StructureDefinition/custom', valueString: 'custom' } }
    let(:other_extension) { { url: 'http://example.org/fhir/StructureDefinition/other', valueString: 'other' } }

    let(:claim_response_entry) do
      { fullUrl: 'urn:uuid:claim-response', resource: {
        resourceType: 'ClaimResponse', id: 'claim-response', status: 'active',
        use: 'preauthorization', outcome: 'complete', extension: [custom_extension]
      } }
    end

    def patient_entry(extension: [], name_extension: [], birth_date_extension: [], given_extension: [])
      { fullUrl: 'urn:uuid:patient', resource: {
        resourceType: 'Patient', id: 'patient', extension:,
        name: [{ family: 'Example', extension: name_extension,
                 given: %w[First Middle], _given: [nil, { extension: given_extension }] }],
        birthDate: '2000-01-01', _birthDate: { extension: birth_date_extension }
      } }
    end

    def bundle_with(*entries)
      FHIR.from_contents({ resourceType: 'Bundle', type: 'collection', entry: entries }.to_json)
    end

    before do
      allow(test_instance).to receive(:validate_pa_response_body_structure)
      allow(test_instance).to receive(:resource_is_valid?).and_call_original
    end

    def validators_used_for(resource_type)
      validators = []
      expect(test_instance).to have_received(:resource_is_valid?).at_least(:once) do |**args|
        validators << args[:validator] if args[:resource].resourceType == resource_type
      end
      validators.uniq
    end

    # v2.2.1 so the US Core fallback validates the (unreferenced) Patient entry on its own.
    def validate(response_bundle, request_bundle)
      test_instance.perform_bundle_validation(response_bundle, 'submit', 'response', 'v2.2.1',
                                              validator: :no_custom_extensions, echoed_from: request_bundle)
    end

    it 'uses the default validator for a resource echoed with the extensions it had in the request' do
      request_bundle = bundle_with(patient_entry(extension: [custom_extension], name_extension: [other_extension]))
      response_bundle = bundle_with(claim_response_entry,
                                    patient_entry(extension: [custom_extension], name_extension: [other_extension]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:default])
      expect(validators_used_for('ClaimResponse')).to eq([:no_custom_extensions])
      expect(validators_used_for('Bundle')).to eq([:no_custom_extensions])
    end

    it 'accepts the request Bundle as JSON' do
      request_json = bundle_with(patient_entry(extension: [custom_extension])).to_json
      response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [custom_extension]))

      validate(response_bundle, request_json)

      expect(validators_used_for('Patient')).to eq([:default])
    end

    it 'uses the specified validator for an echoed resource with an extension not in the request' do
      request_bundle = bundle_with(patient_entry(extension: [custom_extension]))
      response_bundle = bundle_with(claim_response_entry,
                                    patient_entry(extension: [custom_extension], name_extension: [other_extension]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:no_custom_extensions])
    end

    it 'uses the specified validator for an echoed resource whose extension value was changed' do
      request_bundle = bundle_with(patient_entry(extension: [custom_extension]))
      response_bundle = bundle_with(claim_response_entry,
                                    patient_entry(extension: [custom_extension.merge(valueString: 'changed')]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:no_custom_extensions])
    end

    it 'uses the specified validator for an echoed resource with an extension moved to a different element' do
      request_bundle = bundle_with(patient_entry(extension: [custom_extension]))
      response_bundle = bundle_with(claim_response_entry, patient_entry(name_extension: [custom_extension]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:no_custom_extensions])
    end

    it 'uses the specified validator for an echoed resource with a primitive extension not in the request' do
      request_bundle = bundle_with(patient_entry)
      response_bundle = bundle_with(claim_response_entry, patient_entry(birth_date_extension: [custom_extension]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:no_custom_extensions])
    end

    it 'uses the default validator for an echoed resource with the primitive extensions it had in the request' do
      request_bundle = bundle_with(patient_entry(birth_date_extension: [custom_extension],
                                                 given_extension: [other_extension]))
      response_bundle = bundle_with(claim_response_entry,
                                    patient_entry(birth_date_extension: [custom_extension],
                                                  given_extension: [other_extension]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:default])
    end

    it 'uses the default validator for an echoed resource whose repeating elements were reordered' do
      names = [{ family: 'First', extension: [custom_extension] }, { family: 'Second' }]
      request_bundle = bundle_with({ fullUrl: 'urn:uuid:patient',
                                     resource: { resourceType: 'Patient', id: 'patient', name: names } })
      response_bundle = bundle_with(claim_response_entry,
                                    { fullUrl: 'urn:uuid:patient',
                                      resource: { resourceType: 'Patient', id: 'patient', name: names.reverse } })

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:default])
    end

    it 'ignores reference values within echoed extensions' do
      reference_extension = { url: 'http://example.org/fhir/StructureDefinition/custom-reference',
                              valueReference: { reference: 'Practitioner/example', display: 'Example' } }
      rewritten_extension = reference_extension.deep_merge(valueReference: { reference: 'urn:uuid:practitioner' })
      request_bundle = bundle_with(patient_entry(extension: [reference_extension]))
      response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [rewritten_extension]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:default])
    end

    it 'uses the specified validator for an echoed extension whose non-reference content changed' do
      reference_extension = { url: 'http://example.org/fhir/StructureDefinition/custom-reference',
                              valueReference: { reference: 'Practitioner/example', display: 'Example' } }
      changed_extension = reference_extension.deep_merge(valueReference: { display: 'Changed' })
      request_bundle = bundle_with(patient_entry(extension: [reference_extension]))
      response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [changed_extension]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:no_custom_extensions])
    end

    it 'handles resource types without an identifier element' do
      binary = lambda do |id|
        { fullUrl: "urn:uuid:#{id}", resource: { resourceType: 'Binary', id:, contentType: 'text/plain' } }
      end
      request_bundle = bundle_with(binary.call('request-binary'))
      response_bundle = bundle_with(claim_response_entry, binary.call('response-binary'))

      expect { validate(response_bundle, request_bundle) }.to_not raise_error
      expect(validators_used_for('Binary')).to eq([:no_custom_extensions])
    end

    it 'determines the validator for a resource once, however many profiles it is validated against' do
      request_bundle = bundle_with(patient_entry(extension: [custom_extension]))
      response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [custom_extension]))
      allow(test_instance).to receive(:entry_validation_settings).and_call_original
      allow(test_instance).to receive(:us_core_profile_urls_for_resource)
        .and_return(['http://example.org/profile-a', 'http://example.org/profile-b'])
      allow(test_instance).to receive(:resource_is_valid?) do |**args|
        args[:resource].resourceType != 'Patient'
      end

      validate(response_bundle, request_bundle)

      expect(test_instance).to have_received(:entry_validation_settings)
        .with('urn:uuid:patient', an_instance_of(FHIR::Patient)).once
      expect(validators_used_for('Patient')).to eq([:default])
    end

    describe 'when an echoed resource adds extensions' do
      def unknown_extension_issue(location, url)
        Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'location' => location, 'level' => 'ERROR',
                       'message' => "The extension #{url} could not be found so is not allowed here" },
          target: {},
          filtered: false
        )
      end

      def other_issue(location, message = 'some other problem')
        Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'location' => location, 'level' => 'ERROR', 'message' => message },
          target: {},
          filtered: false
        )
      end

      # Reports the given issues for the Patient, as the strict validator would.
      def stub_patient_issues(*issues)
        allow(test_instance).to receive(:resource_is_valid?) do |**args|
          next true unless args[:resource].resourceType == 'Patient'

          args[:validator_response_details]&.concat(issues)
          false
        end
      end

      let(:request_bundle) do
        bundle_with(patient_entry(extension: [other_extension, custom_extension]))
      end
      let(:response_bundle) do
        bundle_with(claim_response_entry,
                    patient_entry(extension: [custom_extension, other_extension],
                                  name_extension: [custom_extension]))
      end

      it 'reports only the extensions that were not echoed' do
        stub_patient_issues(unknown_extension_issue('Patient.extension[0]', custom_extension[:url]),
                            unknown_extension_issue('Patient.extension[1]', other_extension[:url]),
                            unknown_extension_issue('Patient.name[0].extension[0]', custom_extension[:url]))

        messages = validate(response_bundle, request_bundle).map { |message| message[:message] }

        expect(messages).to include(a_string_starting_with('Patient.name[0].extension[0]: '))
        expect(messages).to_not include(a_string_starting_with('Patient.extension['))
        expect(validators_used_for('Patient')).to eq([:no_custom_extensions])
      end

      it 'explains an extension that is at a different element in the request' do
        stub_patient_issues(unknown_extension_issue('Patient.name[0].extension[0]', custom_extension[:url]))

        messages = validate(response_bundle, request_bundle).map { |message| message[:message] }

        expect(messages).to include(
          "Patient.name[0].extension[0]: extension #{custom_extension[:url]} in an echoed resource is not in the " \
          'source resource at this element.'
        )
      end

      it 'explains an extension whose content is different in the request' do
        response_bundle = bundle_with(claim_response_entry,
                                      patient_entry(extension: [custom_extension.merge(valueString: 'changed')]))
        stub_patient_issues(unknown_extension_issue('Patient.extension[0]', custom_extension[:url]))

        messages = validate(response_bundle, request_bundle).map { |message| message[:message] }

        expect(messages).to include(
          "Patient.extension[0]: echoed extension #{custom_extension[:url]} contained a different value than in " \
          'the source resource.'
        )
      end

      it 'explains extensions on an echoed resource that had none in the request' do
        response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [custom_extension]))
        stub_patient_issues(unknown_extension_issue('Patient.extension[0]', custom_extension[:url]))

        messages = validate(response_bundle, bundle_with(patient_entry)).map { |message| message[:message] }

        expect(messages).to include(a_string_including('is not in the source resource at this element'))
      end

      it 'does not explain extensions on a resource that is not echoed' do
        response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [custom_extension]))
        stub_patient_issues(unknown_extension_issue('Patient.extension[0]', custom_extension[:url]))

        messages = validate(response_bundle, nil).map { |message| message[:message] }

        expect(messages).to include(a_string_ending_with('could not be found so is not allowed here'))
      end

      it 'reports only the primitive extensions that were not echoed' do
        request_bundle = bundle_with(patient_entry(birth_date_extension: [custom_extension]))
        response_bundle = bundle_with(claim_response_entry,
                                      patient_entry(birth_date_extension: [custom_extension],
                                                    given_extension: [custom_extension]))
        stub_patient_issues(unknown_extension_issue('Patient.birthDate.extension[0]', custom_extension[:url]),
                            unknown_extension_issue('Patient.name[0].given[1].extension[0]', custom_extension[:url]))

        messages = validate(response_bundle, request_bundle).map { |message| message[:message] }

        expect(messages).to include(a_string_starting_with('Patient.name[0].given[1].extension[0]: '))
        expect(messages).to_not include(a_string_starting_with('Patient.birthDate.extension[0]: '))
        expect(validators_used_for('Patient')).to eq([:no_custom_extensions])
      end

      it 'keeps issues at echoed extensions that are not about the extension itself' do
        stub_patient_issues(other_issue('Patient.extension[0]'),
                            unknown_extension_issue('Patient.name[0].extension[0]', custom_extension[:url]))

        messages = validate(response_bundle, request_bundle).map { |message| message[:message] }

        expect(messages).to include('Patient.extension[0]: some other problem')
      end

      it 'keeps other issues that name an extension, whether or not it was echoed' do
        response_bundle = bundle_with(claim_response_entry,
                                      patient_entry(extension: [other_extension, custom_extension],
                                                    name_extension: [custom_extension]))
        wrong_type = ->(url) { "The Extension '#{url}' definition allows for the types [string] but found type x" }
        stub_patient_issues(other_issue('Patient.extension[0]', wrong_type.call(other_extension[:url])),
                            other_issue('Patient.name[0].extension[0]', wrong_type.call(custom_extension[:url])))

        messages = validate(response_bundle, request_bundle).map { |message| message[:message] }

        expect(messages).to include("Patient.extension[0]: #{wrong_type.call(other_extension[:url])}",
                                    "Patient.name[0].extension[0]: #{wrong_type.call(custom_extension[:url])}")
      end

      it 'drops the default validator notes that echoed extensions are unknown' do
        response_bundle = bundle_with(claim_response_entry,
                                      patient_entry(extension: [other_extension, custom_extension]))
        unknown_note = lambda do |location, url|
          Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
            raw_issue: { 'location' => location, 'level' => 'INFORMATION', 'message' => "Unknown extension #{url}" },
            target: {},
            filtered: false
          )
        end
        stub_patient_issues(unknown_note.call('Patient.extension[0]', other_extension[:url]),
                            unknown_note.call('Patient.extension[1]', custom_extension[:url]),
                            other_issue('Patient.extension[1]'))

        messages = validate(response_bundle, request_bundle).map { |message| message[:message] }

        expect(validators_used_for('Patient')).to eq([:default])
        expect(messages).to_not include(a_string_including('Unknown extension'))
        expect(messages).to include('Patient.extension[1]: some other problem')
      end

      it 'keeps issues whose location is not an extension in the resource' do
        stub_patient_issues(unknown_extension_issue('Patient.extension[5]', custom_extension[:url]),
                            unknown_extension_issue('Patient.name[0]', custom_extension[:url]))

        messages = validate(response_bundle, request_bundle).map { |message| message[:message] }

        expect(messages).to include(a_string_starting_with('Patient.extension[5]: '),
                                    a_string_starting_with('Patient.name[0]: '))
      end
    end

    describe 'echoed resource info message' do
      def info_messages(response_bundle, request_bundle)
        validate(response_bundle, request_bundle).select { |message| message[:type] == 'info' }
          .pluck(:message)
      end

      it 'names an echoed resource and the extensions it keeps from the request' do
        request_bundle = bundle_with(patient_entry(extension: [custom_extension], name_extension: [other_extension]))
        response_bundle = bundle_with(claim_response_entry,
                                      patient_entry(extension: [custom_extension], name_extension: [custom_extension]))

        expect(info_messages(response_bundle, request_bundle)).to eq(
          ['Patient urn:uuid:patient echoes the Patient in the request (matched by fullUrl and id), so these ' \
           "extensions unchanged from the request are allowed in it: #{custom_extension[:url]}."]
        )
      end

      it 'names an echoed resource that keeps no extensions from the request' do
        request_bundle = bundle_with(patient_entry)
        response_bundle = bundle_with(claim_response_entry, patient_entry)

        expect(info_messages(response_bundle, request_bundle))
          .to eq(['Patient urn:uuid:patient echoes the Patient in the request (matched by fullUrl and id).'])
      end

      it 'notes the identifying fields that differ from the request' do
        identifier = ->(value) { [{ system: 'http://example.org/ids', value: }] }
        request_bundle = bundle_with(
          { fullUrl: 'urn:uuid:request-patient',
            resource: { resourceType: 'Patient', id: 'patient', identifier: identifier.call('1') } }
        )
        response_bundle = bundle_with(
          claim_response_entry,
          { fullUrl: 'urn:uuid:patient',
            resource: { resourceType: 'Patient', id: 'patient', identifier: identifier.call('2') } }
        )

        expect(info_messages(response_bundle, request_bundle)).to eq(
          ['Patient urn:uuid:patient echoes the Patient in the request (matched by id; fullUrl and identifiers ' \
           'differ).']
        )
      end

      it 'is not added for resources that are not echoed' do
        response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [custom_extension]))

        expect(info_messages(response_bundle, nil)).to be_empty
      end

      it 'is not added when the default validator is specified' do
        request_bundle = bundle_with(patient_entry)
        response_bundle = bundle_with(claim_response_entry, patient_entry)

        messages = test_instance.perform_bundle_validation(response_bundle, 'submit', 'response', 'v2.2.1',
                                                           echoed_from: request_bundle)

        expect(messages.pluck(:type)).to_not include('info')
      end
    end

    it 'uses the specified validator for a resource not in the request' do
      request_bundle = bundle_with(
        { fullUrl: 'urn:uuid:other-patient',
          resource: { resourceType: 'Patient', id: 'other-patient', extension: [custom_extension] } }
      )
      response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [custom_extension]))

      validate(response_bundle, request_bundle)

      expect(validators_used_for('Patient')).to eq([:no_custom_extensions])
    end

    it 'uses the specified validator for every resource when no request Bundle is given' do
      response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [custom_extension]))

      validate(response_bundle, nil)

      expect(test_instance).to_not have_received(:resource_is_valid?).with(hash_including(validator: :default))
    end

    it 'uses the default validator for every resource when the default validator is specified' do
      request_bundle = bundle_with(patient_entry)
      response_bundle = bundle_with(claim_response_entry, patient_entry(extension: [custom_extension]))

      test_instance.perform_bundle_validation(response_bundle, 'submit', 'response', 'v2.2.1',
                                              echoed_from: request_bundle)

      expect(test_instance).to_not have_received(:resource_is_valid?)
        .with(hash_including(validator: :no_custom_extensions))
    end
  end

  describe '#perform_no_custom_extensions_parameters_validation' do
    let(:test_instance) do
      Class.new do
        include DaVinciPASTestKit::PasBundleValidation

        def resource_is_valid?(**)
          true
        end
      end.new
    end
    let(:parameters) do
      FHIR::Parameters.new(parameter: [{ name: 'return', resource: FHIR::Bundle.new(type: 'collection') }])
    end

    def issue(location, message)
      Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
        raw_issue: { 'location' => location, 'level' => 'ERROR', 'message' => message },
        target: {},
        filtered: false
      )
    end

    it 'validates against the base Parameters definition with the no custom extensions validator' do
      allow(test_instance).to receive(:resource_is_valid?).and_call_original

      test_instance.perform_no_custom_extensions_parameters_validation(parameters)

      expect(test_instance).to have_received(:resource_is_valid?)
        .with(hash_including(resource: parameters, validator: :no_custom_extensions)).once
      expect(test_instance).to_not have_received(:resource_is_valid?).with(hash_including(:profile_url))
    end

    it 'reports issues with the wrapper but not within the wrapped resources' do
      allow(test_instance).to receive(:resource_is_valid?) do |**args|
        args[:validator_response_details].push(
          issue('Parameters.extension[0]', 'wrapper extension not allowed'),
          issue('Parameters.parameter[0].extension[0]', 'parameter extension not allowed'),
          issue('Parameters.parameter[0].resource.entry[0]', 'wrapped Bundle issue'),
          issue('Parameters.parameter[1].part[0].resource', 'wrapped part resource issue')
        )
        false
      end

      messages = test_instance.perform_no_custom_extensions_parameters_validation(parameters)

      expect(messages).to contain_exactly(
        { type: 'error', message: 'Parameters.extension[0]: wrapper extension not allowed' },
        { type: 'error', message: 'Parameters.parameter[0].extension[0]: parameter extension not allowed' }
      )
    end
  end

  describe 'US Core profile fallback' do
    let(:test_instance) do
      Class.new do
        include DaVinciPASTestKit::PasBundleValidation

        # Stands in for the runnable's suite option selections, read by us_core_version.
        attr_writer :suite_options

        def suite_options
          @suite_options ||= {}
        end

        def evaluate_fhirpath(**)
          []
        end

        def messages
          @messages ||= []
        end

        def resource_is_valid?(**)
          true
        end
      end.new
    end

    def us_core_profile_url(profile_id, version = test_instance.us_core_version)
      "#{described_class::US_CORE_PROFILE_BASE}/#{profile_id}|#{version}"
    end

    def select_us_core_version(version)
      test_instance.suite_options = { us_core_version: version }
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

    def claim_encounter_fhirpath
      "Claim.extension.where(url = '#{described_class::CLAIM_ENCOUNTER_EXTENSION_URL}').value"
    end

    describe '#us_core_profile_fallback_enabled?' do
      it 'returns true for PAS v2.2.x versions' do
        expect(test_instance.send(:us_core_profile_fallback_enabled?, '2.2.1')).to be(true)
        expect(test_instance.send(:us_core_profile_fallback_enabled?, '2.2.1')).to be(true)
        # Accepts v-prefixed version strings as used by ig_version inputs
        expect(test_instance.send(:us_core_profile_fallback_enabled?, 'v2.2.1')).to be(true)
      end

      it 'returns false for PAS v2.0.1' do
        expect(test_instance.send(:us_core_profile_fallback_enabled?, '2.0.1')).to be(false)
      end
    end

    describe '#us_core_version' do
      it 'falls back to 6.1.0 when the suite offers no US Core Version option' do
        expect(test_instance.us_core_version).to eq(DaVinciPASTestKit::PASConstants::DEFAULT_US_CORE_VERSION)
        expect(test_instance.us_core_version).to eq('6.1.0')
      end

      it 'uses the selected US Core Version suite option' do
        select_us_core_version('3.1.1')
        expect(test_instance.us_core_version).to eq('3.1.1')
      end
    end

    describe 'with a selected US Core version' do
      let(:us_core_versions) { ['3.1.1', '6.1.0', '7.0.0'] }

      def fallback_profile_urls(resource)
        entry = bundle_entry(resource, "urn:uuid:#{resource.id}")
        test_instance.send(:reset_bundle_profile_inference_state)
        test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.2.1')
        test_instance.bundle_resources_target_profile_map["urn:uuid:#{resource.id}"][:profile_urls]
      end

      it 'versions fallback profile URLs with the selected version' do
        us_core_versions.each do |version|
          select_us_core_version(version)

          expect(fallback_profile_urls(FHIR::Patient.new(id: 'patient-1')))
            .to contain_exactly(us_core_profile_url('us-core-patient', version))
        end
      end

      it 'appends the selected version to unversioned US Core profile URLs' do
        select_us_core_version('7.0.0')
        url = "#{described_class::US_CORE_PROFILE_BASE}/us-core-encounter"
        base_profile = 'http://hl7.org/fhir/StructureDefinition/Encounter'

        expect(test_instance.send(:profile_url_for_validation, url, base_profile, '2.2.1')).to eq("#{url}|7.0.0")
      end

      it 'leaves a declared US Core profile URL unversioned when the selected version does not define it' do
        url = "#{described_class::US_CORE_PROFILE_BASE}/us-core-coverage"
        base_profile = 'http://hl7.org/fhir/StructureDefinition/Coverage'

        select_us_core_version('3.1.1')
        expect(test_instance.send(:profile_url_for_validation, url, base_profile, '2.2.1')).to eq(url)

        select_us_core_version('6.1.0')
        expect(test_instance.send(:profile_url_for_validation, url, base_profile, '2.2.1')).to eq("#{url}|6.1.0")
      end

      it 'validates a declared US Core Condition profile against 3.1.1, the only version that defines it' do
        url = "#{described_class::US_CORE_PROFILE_BASE}/#{described_class::US_CORE_CONDITION_PROFILE_ID}"
        base_profile = 'http://hl7.org/fhir/StructureDefinition/Condition'

        us_core_versions.each do |version|
          select_us_core_version(version)

          expect(test_instance.send(:profile_url_for_validation, url, base_profile, '2.2.1')).to eq("#{url}|3.1.1")
          expect(test_instance.send(:us_core_profile_available?, described_class::US_CORE_CONDITION_PROFILE_ID))
            .to be(version == '3.1.1')
        end
      end

      it 'validates a declared US Core profile unversioned when the selected version does not define it' do
        select_us_core_version('3.1.1')
        coverage = FHIR::Coverage.new(id: 'coverage-1')
        url = "#{described_class::US_CORE_PROFILE_BASE}/us-core-coverage"
        test_instance.add_resource_target_profile_to_map('urn:uuid:coverage-1', coverage, url)
        allow(test_instance).to receive(:resource_is_valid?).and_return(true)

        test_instance.validate_bundle_entries_against_profiles('2.2.1')

        expect(test_instance).to have_received(:resource_is_valid?)
          .with(resource: coverage, profile_url: url, add_messages_to_runnable: false, validator: :default,
                validator_response_details: anything)
      end

      it 'uses the base R4 sentinel for resource types that US Core 3.1.1 has no profile for' do
        select_us_core_version('3.1.1')

        expect(fallback_profile_urls(FHIR::Coverage.new(id: 'coverage-1')))
          .to contain_exactly(described_class::BASE_R4_PROFILE)
      end

      it 'uses the US Core Coverage profile for 6.1.0 and 7.0.0' do
        ['6.1.0', '7.0.0'].each do |version|
          select_us_core_version(version)

          expect(fallback_profile_urls(FHIR::Coverage.new(id: 'coverage-1')))
            .to contain_exactly(us_core_profile_url('us-core-coverage', version))
        end
      end

      it 'uses the single US Core 3.1.1 Condition profile regardless of category' do
        select_us_core_version('3.1.1')
        condition = FHIR::Condition.new(
          id: 'condition-1',
          category: [codeable_concept(described_class::TERMINOLOGY_CONDITION_CATEGORY_SYSTEM, 'encounter-diagnosis')]
        )

        expect(fallback_profile_urls(condition))
          .to contain_exactly(us_core_profile_url(described_class::US_CORE_CONDITION_PROFILE_ID, '3.1.1'))
      end

      it 'splits Condition by category for 6.1.0 and 7.0.0' do
        condition = FHIR::Condition.new(
          id: 'condition-1',
          category: [codeable_concept(described_class::TERMINOLOGY_CONDITION_CATEGORY_SYSTEM, 'encounter-diagnosis')]
        )

        ['6.1.0', '7.0.0'].each do |version|
          select_us_core_version(version)

          expect(fallback_profile_urls(condition))
            .to contain_exactly(us_core_profile_url(described_class::US_CORE_CONDITION_ENCOUNTER_DIAGNOSIS_PROFILE_ID,
                                                    version))
        end
      end

      it 'uses the base R4 sentinel for an Observation whose candidate profiles postdate US Core 3.1.1' do
        select_us_core_version('3.1.1')
        # heart rate, vital signs, clinical result, and simple observation were all added after 3.1.1
        observation = FHIR::Observation.new(
          id: 'observation-1',
          code: codeable_concept(described_class::LOINC_SYSTEM, '8867-4'),
          category: [codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'vital-signs')]
        )

        expect(fallback_profile_urls(observation)).to contain_exactly(described_class::BASE_R4_PROFILE)
      end

      it 'keeps the Observation profiles that US Core 3.1.1 defines' do
        select_us_core_version('3.1.1')
        lab = FHIR::Observation.new(
          id: 'lab-1',
          code: codeable_concept(described_class::LOINC_SYSTEM, '99999-9'),
          category: [codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'laboratory')]
        )
        pulse_oximetry = FHIR::Observation.new(
          id: 'pulse-ox-1',
          code: codeable_concept(described_class::LOINC_SYSTEM, '59408-5')
        )

        expect(fallback_profile_urls(lab))
          .to eq([us_core_profile_url(described_class::US_CORE_OBSERVATION_LAB_PROFILE_ID, '3.1.1'),
                  described_class::BASE_R4_PROFILE])
        # code-specific profiles are the only candidate in every version, so no catch-all follows
        expect(fallback_profile_urls(pulse_oximetry))
          .to contain_exactly(us_core_profile_url('us-core-pulse-oximetry', '3.1.1'))
      end

      it 'ends the category-based Observation candidates with the base R4 sentinel for US Core 3.1.1' do
        select_us_core_version('3.1.1')
        # Simple Observation is the catch-all from 6.1.0 on; the base resource plays that role in 3.1.1.
        observation = FHIR::Observation.new(
          id: 'observation-1',
          category: [codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'social-history')]
        )
        expected_profile_urls = [
          us_core_profile_url(described_class::US_CORE_SMOKING_STATUS_PROFILE_ID, '3.1.1'),
          described_class::BASE_R4_PROFILE
        ]

        expect(fallback_profile_urls(observation)).to eq(expected_profile_urls)
      end

      it 'uses the code-specific Observation profiles added in US Core 7.0.0 only when 7.0.0 is selected' do
        observation = FHIR::Observation.new(
          id: 'observation-1',
          code: codeable_concept(described_class::LOINC_SYSTEM, '96607-7'),
          category: [codeable_concept(described_class::OBSERVATION_CATEGORY_SYSTEM, 'vital-signs')]
        )

        select_us_core_version('7.0.0')
        expect(fallback_profile_urls(observation))
          .to contain_exactly(us_core_profile_url('us-core-average-blood-pressure', '7.0.0'))

        # without the average blood pressure profile, the category-based candidates apply
        select_us_core_version('6.1.0')
        category_profile_urls = [
          described_class::US_CORE_VITAL_SIGNS_PROFILE_ID,
          described_class::US_CORE_OBSERVATION_CLINICAL_RESULT_PROFILE_ID,
          described_class::US_CORE_SIMPLE_OBSERVATION_PROFILE_ID
        ].map { |profile_id| us_core_profile_url(profile_id, '6.1.0') }
        expect(fallback_profile_urls(observation)).to eq(category_profile_urls)
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
        test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.2.1')

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

        test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.2.1')

        expect(test_instance.bundle_resources_target_profile_map['urn:uuid:patient-1'][:profile_urls])
          .to contain_exactly(us_core_profile_url('us-core-patient'))
      end

      it 'applies the base R4 sentinel for NutritionOrder' do
        nutrition_order = FHIR::NutritionOrder.new(id: 'nutrition-order-1')
        entry = bundle_entry(nutrition_order, 'urn:uuid:nutrition-order-1')

        test_instance.send(:add_us_core_profiles_to_unprofiled_entries, [entry], '2.2.1')

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
      allow(test_instance).to receive(:evaluate_fhirpath).and_return([])

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.1',
        'submit'
      )

      expect(
        test_instance
          .bundle_resources_target_profile_map['http://example.com/fhir/DocumentReference/doc-1'][:profile_urls]
      ).to contain_exactly(us_core_profile_url('us-core-documentreference'))
    end

    describe '#profile_url_without_version' do
      it 'strips the version suffix from a versioned URL' do
        url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim|2.2.1'
        expect(test_instance.send(:profile_url_without_version, url))
          .to eq('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim')
      end

      it 'returns the URL unchanged when no version suffix is present' do
        url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim'
        expect(test_instance.send(:profile_url_without_version, url)).to eq(url)
      end

      it 'converts the BASE_R4_PROFILE sentinel symbol to a string without appending anything' do
        result = test_instance.send(:profile_url_without_version, described_class::BASE_R4_PROFILE)
        expect(result).to eq(described_class::BASE_R4_PROFILE.to_s)
      end
    end

    describe '#us_core_profile_url?' do
      it 'returns true for an unversioned US Core profile URL' do
        url = "#{described_class::US_CORE_PROFILE_BASE}/us-core-patient"
        expect(test_instance.send(:us_core_profile_url?, url)).to be(true)
      end

      it 'returns true for a versioned US Core profile URL' do
        url = "#{described_class::US_CORE_PROFILE_BASE}/us-core-encounter|#{test_instance.us_core_version}"
        expect(test_instance.send(:us_core_profile_url?, url)).to be(true)
      end

      it 'returns false for a PAS profile URL' do
        url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim'
        expect(test_instance.send(:us_core_profile_url?, url)).to be(false)
      end
    end

    describe '#profile_url_for_validation' do
      let(:base_profile) { 'http://hl7.org/fhir/StructureDefinition/Encounter' }

      it 'returns a URL that already includes a version separator unchanged' do
        url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim|2.2.1'
        expect(test_instance.send(:profile_url_for_validation, url, base_profile, '2.2.1')).to eq(url)
      end

      it 'appends the US Core version to an unversioned US Core URL' do
        url = "#{described_class::US_CORE_PROFILE_BASE}/us-core-encounter"
        expect(test_instance.send(:profile_url_for_validation, url, base_profile, '2.2.1'))
          .to eq("#{url}|#{test_instance.us_core_version}")
      end

      it 'returns a base R4 profile URL unchanged when it matches the base profile' do
        expect(test_instance.send(:profile_url_for_validation, base_profile, base_profile, '2.2.1'))
          .to eq(base_profile)
      end

      it 'appends the IG version to an unversioned PAS profile URL' do
        url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter'
        expect(test_instance.send(:profile_url_for_validation, url, base_profile, '2.2.1'))
          .to eq("#{url}|2.2.1")
      end
    end

    describe '#resource_full_url_for_entry' do
      it 'returns the entry fullUrl when present' do
        patient = FHIR::Patient.new(id: 'patient-1')
        entry = FHIR::Bundle::Entry.new(fullUrl: 'http://example.com/fhir/Patient/patient-1', resource: patient)
        expect(test_instance.send(:resource_full_url_for_entry, entry))
          .to eq('http://example.com/fhir/Patient/patient-1')
      end

      it 'falls back to ResourceType/id when fullUrl is absent' do
        patient = FHIR::Patient.new(id: 'patient-1')
        entry = FHIR::Bundle::Entry.new(resource: patient)
        expect(test_instance.send(:resource_full_url_for_entry, entry)).to eq('Patient/patient-1')
      end
    end

    describe '#reset_bundle_profile_inference_state' do
      it 'clears the profile map so a subsequent call starts fresh' do
        patient = FHIR::Patient.new(id: 'patient-1')
        test_instance.add_resource_target_profile_to_map(
          'urn:uuid:patient-1', patient, us_core_profile_url('us-core-patient')
        )
        expect(test_instance.bundle_resources_target_profile_map).to_not be_empty

        test_instance.send(:reset_bundle_profile_inference_state)

        expect(test_instance.bundle_resources_target_profile_map).to be_empty
      end
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
        '2.2.1',
        'submit'
      )

      expect(
        test_instance
          .bundle_resources_target_profile_map['http://example.com/fhir/Encounter/encounter-1'][:profile_urls]
      ).to contain_exactly('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter|2.2.1')
    end

    it 'traverses the R5 Claim encounter extension to the PAS Encounter profile' do
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
        if path == claim_encounter_fhirpath
          [{ 'type' => 'Reference', 'element' => FHIR::Reference.new(reference: 'Encounter/encounter-1') }]
        else
          []
        end
      end

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.1',
        'submit'
      )

      expect(
        test_instance
          .bundle_resources_target_profile_map['http://example.com/fhir/Encounter/encounter-1'][:profile_urls]
      ).to contain_exactly('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter')
    end

    it 'traverses the R5 Claim encounter extension for profile-claim-update claims (regression)' do
      # A claim with .related triggers profile-claim-update in v2.2.1; encounter extension must
      # still be traversed and assigned profile-encounter (not a US Core fallback).
      claim = FHIR::Claim.new(
        id: 'claim-1',
        related: [{ relationship: { coding: [{ code: 'prior' }] } }]
      )
      encounter = FHIR::Encounter.new(id: 'encounter-1')
      bundle = FHIR::Bundle.new(
        entry: [
          bundle_entry(claim, 'http://example.com/fhir/Claim/claim-1'),
          bundle_entry(encounter, 'http://example.com/fhir/Encounter/encounter-1')
        ]
      )

      allow(test_instance).to receive(:validate_bundle_entries_against_profiles)
      allow(test_instance).to receive(:evaluate_fhirpath) do |path:, **|
        if path == claim_encounter_fhirpath
          [{ 'type' => 'Reference', 'element' => FHIR::Reference.new(reference: 'Encounter/encounter-1') }]
        else
          []
        end
      end

      test_instance.validate_resources_conformance_against_profile(
        bundle,
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle',
        '2.2.1',
        'submit'
      )

      expect(
        test_instance
          .bundle_resources_target_profile_map['http://example.com/fhir/Encounter/encounter-1'][:profile_urls]
      ).to include('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter')
    end

    it 'uses the base R4 sentinel to validate without a profile URL' do
      nutrition_order = FHIR::NutritionOrder.new(id: 'nutrition-order-1')

      test_instance.add_resource_target_profile_to_map(
        'urn:uuid:nutrition-order-1',
        nutrition_order,
        described_class::BASE_R4_PROFILE
      )

      allow(test_instance).to receive(:resource_is_valid?)
        .with(resource: nutrition_order, profile_url: nil, validator: :default, add_messages_to_runnable: false,
              validator_response_details: anything)
        .and_return(true)

      test_instance.validate_bundle_entries_against_profiles('2.2.1')

      expect(test_instance).to have_received(:resource_is_valid?)
        .with(resource: nutrition_order, profile_url: nil, validator: :default, add_messages_to_runnable: false,
              validator_response_details: anything)
      expect(test_instance.validation_messages).to be_empty
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
          '2.2.1'
        )
      ).to eq(versioned_profile)
      expect(
        test_instance.send(:profile_url_for_validation, unversioned_us_core_profile, base_profile, '2.2.1')
      ).to eq(versioned_profile)
      expect(
        test_instance.send(:profile_url_for_validation, unversioned_us_core_profile, base_profile, '2.0.1')
      ).to eq(versioned_profile)
      expect(
        test_instance.send(:profile_url_for_validation, pas_profile, base_profile, '2.2.1')
      ).to eq("#{pas_profile}|2.2.1")
      expect(
        test_instance.send(:profile_url_for_validation, base_profile, base_profile, '2.2.1')
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

  describe '#determine_claim_submit_profile_url' do
    let(:test_instance) do
      Class.new { include DaVinciPASTestKit::PasBundleValidation }.new
    end

    let(:base_claim_url) { DaVinciPASTestKit::PASConstants::CLAIM_PROFILE_FIRST_SUBMIT }
    let(:claim_update_url) { DaVinciPASTestKit::PASConstants::CLAIM_PROFILE }

    context 'when version is 2.0.1' do
      it 'returns profile-claim-update regardless of Claim.related' do
        claim = FHIR::Claim.new
        expect(test_instance.send(:determine_claim_submit_profile_url, '2.0.1', claim)).to eq(claim_update_url)
      end
    end

    context 'when version is 2.2.1' do
      it 'returns profile-claim when Claim.related is absent' do
        claim = FHIR::Claim.new
        expect(test_instance.send(:determine_claim_submit_profile_url, '2.2.1', claim)).to eq(base_claim_url)
      end

      it 'returns profile-claim when Claim.related is an empty array' do
        claim = FHIR::Claim.new(related: [])
        expect(test_instance.send(:determine_claim_submit_profile_url, '2.2.1', claim)).to eq(base_claim_url)
      end

      it 'returns profile-claim-update when Claim.related is present' do
        claim = FHIR::Claim.new(related: [{ relationship: { coding: [{ code: 'prior' }] } }])
        expect(test_instance.send(:determine_claim_submit_profile_url, '2.2.1', claim)).to eq(claim_update_url)
      end
    end
  end

  describe '#validate_bundle_entries_against_profiles with multiple profiles' do
    let(:validator_issue_class) { Inferno::DSL::FHIRResourceValidation::ValidatorIssue }
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

    # Versioned URLs pass through profile_url_for_validation unchanged, keeping stub keys predictable
    let(:profile_a) { 'http://example.com/StructureDefinition/profile-a|1.0.0' }
    let(:profile_b) { 'http://example.com/StructureDefinition/profile-b|1.0.0' }
    let(:observation) { FHIR::Observation.new(id: 'obs-1') }

    def make_issue(resource, level:, message:, location: 'Observation.code')
      validator_issue_class.new(
        raw_issue: { 'location' => location, 'level' => level, 'message' => message },
        target: resource
      )
    end

    def stub_validator(issues_by_profile)
      allow(test_instance).to receive(:resource_is_valid?) do |profile_url: nil, validator_response_details: nil, **|
        issues = issues_by_profile.fetch(profile_url, [])
        validator_response_details&.concat(issues)
        issues.reject(&:filtered).none? { |issue| issue.severity == 'error' }
      end
    end

    it 'suppresses error messages from failing profiles when another profile passes' do
      test_instance.add_resource_target_profile_to_map('urn:uuid:obs-1', observation, profile_a)
      test_instance.add_resource_target_profile_to_map('urn:uuid:obs-1', observation, profile_b)
      stub_validator(
        profile_a => [make_issue(observation, level: 'ERROR', message: 'missing required element')],
        profile_b => []
      )

      test_instance.validate_bundle_entries_against_profiles('2.2.1')

      expect(test_instance.messages).to be_empty
      expect(test_instance.validation_messages).to be_empty
    end

    it 'logs non-error messages from the passing profile' do
      test_instance.add_resource_target_profile_to_map('urn:uuid:obs-1', observation, profile_a)
      stub_validator(
        profile_a => [make_issue(observation, level: 'WARNING', message: 'unresolvable value set')]
      )

      test_instance.validate_bundle_entries_against_profiles('2.2.1')

      # Messages go into validation_messages, not straight to the runnable's `messages` - see
      # perform_bundle_validation - so callers get every message, not just a summary line.
      expect(test_instance.messages).to be_empty
      expect(test_instance.validation_messages).to contain_exactly(
        { type: 'warning', message: include('unresolvable value set') }
      )
    end

    it 'logs messages for every candidate profile when all profiles fail' do
      test_instance.add_resource_target_profile_to_map('urn:uuid:obs-1', observation, profile_a)
      test_instance.add_resource_target_profile_to_map('urn:uuid:obs-1', observation, profile_b)
      stub_validator(
        profile_a => [make_issue(observation, level: 'ERROR', message: 'profile a failure')],
        profile_b => [make_issue(observation, level: 'ERROR', message: 'profile b failure')]
      )

      test_instance.validate_bundle_entries_against_profiles('2.2.1')

      expect(test_instance.messages).to be_empty
      expect(test_instance.validation_messages.map { |message| message[:message] }).to contain_exactly(
        include('profile a failure'), include('profile b failure'),
        include('not conformant to any of the target profiles')
      )
    end

    it 'stops validating once a profile passes' do
      test_instance.add_resource_target_profile_to_map('urn:uuid:obs-1', observation, profile_a)
      test_instance.add_resource_target_profile_to_map('urn:uuid:obs-1', observation, profile_b)
      stub_validator(profile_a => [], profile_b => [])

      test_instance.validate_bundle_entries_against_profiles('2.2.1')

      expect(test_instance).to have_received(:resource_is_valid?).once
    end

    it 'excludes filtered validator issues from the logged messages' do
      test_instance.add_resource_target_profile_to_map('urn:uuid:obs-1', observation, profile_a)
      filtered_issue = make_issue(observation, level: 'ERROR', message: 'suppressed x12 message')
      filtered_issue.filtered = true
      stub_validator(profile_a => [filtered_issue])

      test_instance.validate_bundle_entries_against_profiles('2.2.1')

      expect(test_instance.messages).to be_empty
      expect(test_instance.validation_messages).to be_empty
    end

    context 'with PAS datatype constraints' do
      let(:device_request_profile) { 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-devicerequest' }
      let(:device_request) do
        FHIR::DeviceRequest.new(
          id: 'dr-1',
          occurrenceTiming: FHIR::Timing.new(repeat: FHIR::Timing::Repeat.new(duration: 1, durationUnit: 'h'))
        )
      end

      it 'reports a resource that passes validator checks but violates a datatype constraint' do
        test_instance.add_resource_target_profile_to_map('urn:uuid:dr-1', device_request, device_request_profile)
        stub_validator("#{device_request_profile}|2.2.1" => [])

        test_instance.validate_bundle_entries_against_profiles('2.2.1')

        expect(test_instance.messages).to be_empty
        expect(test_instance.validation_messages.map { |message| message[:message] }).to contain_exactly(
          include('prof-1'), include('not conformant to any of the target profiles')
        )
      end

      it 'does not apply datatype constraints for v2.0.1' do
        test_instance.add_resource_target_profile_to_map('urn:uuid:dr-1', device_request, device_request_profile)
        stub_validator("#{device_request_profile}|2.0.1" => [])

        test_instance.validate_bundle_entries_against_profiles('2.0.1')

        expect(test_instance.messages).to be_empty
        expect(test_instance.validation_messages).to be_empty
      end
    end
  end
end
