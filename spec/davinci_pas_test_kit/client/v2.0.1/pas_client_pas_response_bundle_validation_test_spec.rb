RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PasClientResponseBundleValidationTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:access_token) { '1234' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:fhirpath_url) { 'https://example.com/fhirpath/evaluate' }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:operation_outcome_success) do
    {
      outcomes: [{
        issues: []
      }],
      sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
    }
  end
  let(:valid_response_string) do
    File.read(File.join(__dir__, '../../..', 'fixtures', 'valid_pa_response_bundle.json'))
  end
  let(:approval_test) do
    Class.new(DaVinciPASTestKit::DaVinciPASV201::PasClientResponseBundleValidationTest) do
      fhir_resource_validator do
        url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')

        cli_context do
          txServer nil
          displayWarnings true
          disableDefaultResourceFetcher true
        end

        igs('hl7.fhir.us.davinci-pas#2.0.1')
      end

      fhir_resource_validator :no_custom_extensions do
        url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')

        cli_context do
          txServer nil
          displayWarnings true
          disableDefaultResourceFetcher true
          extensions []
        end

        igs('hl7.fhir.us.davinci-pas#2.0.1')
      end

      input :approval_json_response, optional: true

      config({ options: { workflow_tag: DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG } })
    end
  end

  let(:multi_request_test) do
    Class.new(DaVinciPASTestKit::DaVinciPASV201::PasClientResponseBundleValidationTest) do
      fhir_resource_validator :no_custom_extensions do
        url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')

        cli_context do
          txServer nil
          displayWarnings true
          disableDefaultResourceFetcher true
          extensions []
        end

        igs('hl7.fhir.us.davinci-pas#2.0.1')
      end

      input :approval_json_response, optional: true

      config({ options: { workflow_tag: DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, multiple_requests_ok: true } })
    end
  end

  def create_submit_response(bundle_string, tags_list, request_body: nil)
    headers ||= [
      {
        type: 'request',
        name: 'Authorization',
        value: "Bearer #{access_token}"
      }
    ]
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      request_body:,
      response_body: bundle_string,
      tags: tags_list,
      status: 201,
      headers:
    )
  end

  describe 'when verifying submit responses' do
    it 'skips when no tests previously made' do
      result = run(approval_test)
      expect(result.result).to eq('skip')
    end

    it 'skips when no requests made for the specific workflow' do
      create_submit_response(valid_response_string,
                             [DaVinciPASTestKit::DENIAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])
      result = run(approval_test)
      expect(result.result).to eq('skip')
    end

    it 'passes with a valid response' do
      stub_request(:post, validation_url)
        .to_return(status: 200, body: operation_outcome_success.to_json)
      stub_request(:post, /#{fhirpath_url}\?path=ClaimResponse.*/)
        .to_return(status: 200, body: [].to_json)
      stub_request(:post, /#{fhirpath_url}\?path=Patient.*/)
        .to_return(status: 200, body: [].to_json)
      stub_request(:post, /#{fhirpath_url}\?path=Organization.*/)
        .to_return(status: 200, body: [].to_json)
      stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.patient")
        .to_return(status: 200, body: [{ type: 'Reference',
                                         element: { reference: 'Patient/SubscriberExample' } }].to_json)
      stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.insurer")
        .to_return(status: 200, body: [{ type: 'Reference',
                                         element: { reference: 'Organization/InsurerExample' } }].to_json)
      stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.requestor")
        .to_return(status: 200, body: [{ type: 'Reference',
                                         element: { reference: 'Organization/UMOExample' } }].to_json)
      create_submit_response(valid_response_string,
                             [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG,
                              DaVinciPASTestKit::SUBMIT_TAG])

      inputs = { approval_json_response: nil }
      result = run(approval_test, inputs)

      expect(result.result).to eq('pass')
    end

    describe 'with custom extensions' do
      let(:custom_extension_url) { 'http://example.org/fhir/StructureDefinition/custom-extension' }
      let(:custom_extension) { { url: custom_extension_url, valueString: 'custom' } }
      let(:response_hash) { JSON.parse(valid_response_string) }

      def response_resource(resource_type)
        response_hash['entry'].find { |e| e['resource']['resourceType'] == resource_type }['resource']
      end

      def request_with_patient(patient)
        { resourceType: 'Bundle', type: 'collection',
          entry: [{ fullUrl: 'https://prior-auth.davinci.hl7.org/fhir/Patient/SubscriberExample',
                    resource: patient }] }.to_json
      end

      # Mimics the validator: reports the custom extension as unknown only when told not to allow extensions
      # beyond those in the IG, and within the entry resource when validating a Bundle. No sessionId, since
      # both validators are used and each would try to save the same one.
      def validator_response(request)
        body = JSON.parse(request.body)
        context = body['validationContext'] || body['cliContext']
        resource = JSON.parse(body['filesToValidate'].first['fileContent'])
        issues = []
        if context['extensions'] == [] && resource.to_json.include?(custom_extension_url)
          location = unknown_extension_location(resource)
          issues << { level: 'ERROR', location:,
                      message: "#{location}: The extension #{custom_extension_url} could not be found so is " \
                               'not allowed here' }
        end
        { status: 200, body: { outcomes: [{ issues: }] }.to_json }
      end

      def unknown_extension_location(resource)
        return "#{resource['resourceType']}.extension[0]" unless resource['resourceType'] == 'Bundle'

        index = resource['entry'].index { |entry| entry.to_json.include?(custom_extension_url) }
        "Bundle.entry[#{index}].resource.extension[0]"
      end

      before do
        stub_request(:post, validation_url).to_return { |request| validator_response(request) }
        stub_request(:post, /#{fhirpath_url}\?path=.*/)
          .to_return(status: 200, body: [].to_json)
        stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.patient")
          .to_return(status: 200, body: [{ type: 'Reference',
                                           element: { reference: 'Patient/SubscriberExample' } }].to_json)
        stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.insurer")
          .to_return(status: 200, body: [{ type: 'Reference',
                                           element: { reference: 'Organization/InsurerExample' } }].to_json)
        stub_request(:post, "#{fhirpath_url}?path=ClaimResponse.requestor")
          .to_return(status: 200, body: [{ type: 'Reference',
                                           element: { reference: 'Organization/UMOExample' } }].to_json)
      end

      it 'skips when a tester-provided response contains a custom extension' do
        response_resource('ClaimResponse')['extension'] = [custom_extension]
        response_json = response_hash.to_json
        create_submit_response(response_json,
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])

        result = run(approval_test, approval_json_response: response_json)

        expect(result.result).to eq('skip')
        expect(result.result_message).to include("built from tester-provided response in 'approval_json_response'")
        expect(entity_result_messages(approval_test).map(&:message))
          .to include(a_string_including("#{custom_extension_url} could not be found"))
      end

      it 'passes when the custom extension is on a resource echoed from the request with it' do
        patient = response_resource('Patient')
        patient['extension'] = Array(patient['extension']) + [custom_extension]
        request_body = request_with_patient(patient)
        create_submit_response(response_hash.to_json,
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG],
                               request_body:)

        result = run(approval_test, approval_json_response: nil)

        expect(result.result).to eq('pass')
      end

      it 'skips when a tester-provided response adds a custom extension to a resource echoed from the request' do
        request_body = request_with_patient(response_resource('Patient').deep_dup)
        patient = response_resource('Patient')
        patient['extension'] = Array(patient['extension']) + [custom_extension]
        response_json = response_hash.to_json
        create_submit_response(response_json,
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG],
                               request_body:)

        result = run(approval_test, approval_json_response: response_json)

        expect(result.result).to eq('skip')
        expect(entity_result_messages(approval_test).map(&:message))
          .to include(a_string_including("#{custom_extension_url} could not be found"))
      end
    end

    describe 'and failing' do
      it 'indicates the response was generated when no user input' do
        create_submit_response('NOT JSON',
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG,
                                DaVinciPASTestKit::SUBMIT_TAG])

        inputs = { approval_json_response: nil }
        result = run(approval_test, inputs)

        expect(result.result).to eq('skip')
        expect(result.result_message).to include('generated from the submitted claim')
      end

      it 'indicates the response came from the user when user input provided' do
        create_submit_response('NOT JSON',
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG,
                                DaVinciPASTestKit::SUBMIT_TAG])

        inputs = { approval_json_response: 'NOT JSON' }
        result = run(approval_test, inputs)

        expect(result.result).to eq('skip')
        expect(result.result_message).to include("built from tester-provided response in 'approval_json_response'")
      end
    end

    describe 'when multiple requests are loaded' do
      before do
        create_submit_response(valid_response_string,
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])
        create_submit_response(valid_response_string,
                               [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])
      end

      it 'errors when the test does not expect more than one' do
        result = run(approval_test, approval_json_response: nil)

        expect(result.result).to eq('error')
        expect(result.result_message).to include('does not expect more than one')
      end

      it 'checks every request when the test allows multiple, continuing past an invalid one' do
        allow_any_instance_of(described_class).to receive(:perform_bundle_validation).and_return([])
        create_submit_response('NOT JSON', [DaVinciPASTestKit::APPROVAL_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG])

        result = run(multi_request_test, approval_json_response: nil)

        expect(result.result).to eq('skip')
        expect(result.result_message).to include('Response 3')
        messages = entity_result_messages(multi_request_test)
        expect(messages.map(&:message)).to include('Response 3: Invalid JSON.')
        expect(messages.size).to eq(1)
      end
    end
  end

  def entity_result_messages(runnable)
    Inferno::Repositories::Results.new
      .current_results_for_test_session_and_runnables(test_session.id, [runnable])
      .first
      .messages
  end
end
