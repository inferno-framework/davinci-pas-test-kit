# Verifies the suite-level :no_custom_extensions validators that the client suites use for
# responses Inferno sends (which may be tester-provided), as opposed to the :default validators
# used for client requests, which may contain custom extensions.
RSpec.describe 'Client suite :no_custom_extensions validator', :runnable do # rubocop:disable RSpec/DescribeClass
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:runnable) { instance_double(Inferno::Test, add_message: nil, test_session_id: test_session.id) }
  let(:custom_extension_url) { 'http://example.org/fhir/StructureDefinition/custom-extension' }
  let(:claim_response) do
    FHIR::ClaimResponse.new(
      id: 'claim-response',
      status: 'active',
      use: 'preauthorization',
      outcome: 'complete',
      extension: [{ url: custom_extension_url, valueString: 'custom' }]
    )
  end
  # The message the HL7 validator reports for an extension it can't resolve when
  # custom extensions are not allowed.
  let(:unknown_extension_outcome) do
    {
      outcomes: [{
        issues: [{
          level: 'ERROR',
          location: 'ClaimResponse.extension[0]',
          message: "ClaimResponse.extension[0]: The extension #{custom_extension_url} could not be found " \
                   'so is not allowed here'
        }]
      }],
      sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
    }
  end

  def validation_context_from(request)
    body = JSON.parse(request.body)
    body['validationContext'] || body['cliContext']
  end

  {
    'v2.0.1' => DaVinciPASTestKit::DaVinciPASV201::ClientSuite,
    'v2.2.1' => DaVinciPASTestKit::DaVinciPASV221::ClientSuite
  }.each do |version, client_suite|
    describe "in the #{version} client suite" do
      let(:no_custom_extensions_validator) { client_suite.find_validator(:no_custom_extensions) }
      let(:default_validator) { client_suite.find_validator(:default) }

      # Inferno's default context sends extensions ['any'], so this confirms the empty list
      # overrides it rather than being dropped.
      it 'tells the validator not to allow any extensions beyond those in the loaded IGs' do
        stub_request(:post, validation_url)
          .to_return(status: 200, body: { outcomes: [{ issues: [] }] }.to_json)

        no_custom_extensions_validator.resource_is_valid?(claim_response, nil, runnable,
                                                          add_messages_to_runnable: false)

        expect(a_request(:post, validation_url).with { |req| validation_context_from(req)['extensions'] == [] })
          .to have_been_made.once
      end

      it 'loads the same IGs as the default validator' do
        expect(no_custom_extensions_validator.igs).to eq(default_validator.igs)
      end

      it 'allows any extensions in the default validator used for client requests' do
        stub_request(:post, validation_url)
          .to_return(status: 200, body: { outcomes: [{ issues: [] }] }.to_json)

        default_validator.resource_is_valid?(claim_response, nil, runnable, add_messages_to_runnable: false)

        expect(a_request(:post, validation_url).with { |req| validation_context_from(req)['extensions'] == ['any'] })
          .to have_been_made.once
      end

      it 'does not suppress the unknown extension error' do
        stub_request(:post, validation_url)
          .to_return(status: 200, body: unknown_extension_outcome.to_json)

        result = no_custom_extensions_validator.resource_is_valid?(claim_response, nil, runnable,
                                                                   add_messages_to_runnable: true)

        expect(result).to be(false)
        expect(runnable).to have_received(:add_message)
          .with('error', a_string_including("#{custom_extension_url} could not be found"))
      end
    end
  end
end
