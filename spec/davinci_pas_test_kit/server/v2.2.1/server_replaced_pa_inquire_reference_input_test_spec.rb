RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASServerReplacedPAInquireReferenceInputTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v221' }
  let(:test) { described_class }

  def request_bundle(reference_number)
    {
      resourceType: 'Bundle',
      type: 'collection',
      entry: [
        {
          resource: {
            resourceType: 'Claim',
            item: [
              {
                sequence: 1,
                extension: [
                  {
                    url:
                    DaVinciPASTestKit::PASConstants::REFERENCE_NUMBER_EXTENSIONS[:authorization_number],
                    valueString: reference_number
                  },
                  {
                    url:
                    DaVinciPASTestKit::PASConstants::REFERENCE_NUMBER_EXTENSIONS[:administration_reference_number],
                    valueString: reference_number
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  end

  it 'fails when the request body does not contain a reference number' do
    bundle = request_bundle('')

    result = run(
      test,
      must_support_pa_inquire_request_payload: bundle.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'inquiry requests did not contain an authorization number'
    )
  end

  it 'fails when the request body is not valid JSON' do
    result = run(
      test,
      must_support_pa_inquire_request_payload: '{test}'
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'Provide a valid JSON PAS Inquiry Request Bundle.'
    )
  end

  it 'fails when the request body does not contain a request Bundle' do
    operation_outcome = {
      resourceType: 'OperationOutcome'
    }

    result = run(
      test,
      must_support_pa_inquire_request_payload: operation_outcome.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'Each inquiry request body must be a FHIR Bundle.'
    )
  end

  it 'skips when no inquiry request body is provided' do
    result = run(test)

    expect(result.result).to eq('skip')
  end

  it 'passes when provided request body does contain a reference number' do
    bundle = request_bundle('AUTH-0001')

    result = run(
      test,
      must_support_pa_inquire_request_payload: bundle.to_json
    )

    expect(result.result).to eq('pass')
  end
end
