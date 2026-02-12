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
end
