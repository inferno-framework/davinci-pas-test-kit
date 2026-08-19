RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASServerReplacedPAInquireReferenceTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v221' }
  let(:server_endpoint) { 'http://example.com/fhir' }

  let(:test) do
    Class.new(described_class) do
      fhir_client { url :server_endpoint }
      input :server_endpoint
    end
  end

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
                    url: DaVinciPASTestKit::PASConstants::REFERENCE_NUMBER_EXTENSIONS[:authorization_number],
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

  def response_parameters(reference_number)
    {
      resourceType: 'Parameters',
      parameter: [
        {
          name: 'return',
          resource: {
            resourceType: 'Bundle',
            type: 'collection',
            entry: [
              {
                resource: {
                  resourceType: 'ClaimResponse',
                  item: [
                    {
                      itemSequence: 1,
                      extension: [
                        {
                          url: DaVinciPASTestKit::PASConstants::REFERENCE_NUMBER_EXTENSIONS[:authorization_number],
                          valueString: reference_number
                        }
                      ]
                    }
                  ]
                }
              }
            ]
          }
        }
      ]
    }.to_json
  end

  def stub_inquire(response_body, status: 200)
    stub_request(:post, "#{server_endpoint}/Claim/$inquire")
      .to_return(status:, body: response_body)
  end

  it 'passes with a JSON Bundle when the response contains a different reference number' do
    bundle = request_bundle('AUTH-0001')
    stub_inquire(response_parameters('AUTH-0002'))

    result = run(
      test,
      server_endpoint:,
      must_support_pa_inquire_request_payload: bundle.to_json
    )

    expect(result.result).to eq('pass')
  end

  it 'submits every Bundle when provided a list of Bundles' do
    first_bundle = request_bundle('AUTH-0001')
    second_bundle = request_bundle('AUTH-0002')
    stub_inquire(response_parameters('AUTH-0003'))

    result = run(
      test,
      server_endpoint:,
      must_support_pa_inquire_request_payload: [
        first_bundle,
        second_bundle
      ].to_json
    )

    expect(result.result).to eq('pass')
    expect(
      a_request(:post, "#{server_endpoint}/Claim/$inquire")
    ).to have_been_requested.twice
  end

  it 'fails when the response contains the same reference number' do
    bundle = request_bundle('AUTH-0001')
    stub_inquire(response_parameters('AUTH-0001'))

    result = run(
      test,
      server_endpoint:,
      must_support_pa_inquire_request_payload: bundle.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('different authorization number')
  end

  it 'fails when the request body is not valid JSON' do
    result = run(
      test,
      server_endpoint:,
      must_support_pa_inquire_request_payload: '{test}'
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'Provide a valid JSON PAS Inquiry Request Bundle.'
    )
  end

  it 'fails when $inquire response is not 200' do
    bundle = request_bundle('AUTH-0001')
    stub_inquire(
      {
        resourceType: 'OperationOutcome',
        issue: []
      }.to_json,
      status: 400
    )

    result = run(
      test,
      server_endpoint:,
      must_support_pa_inquire_request_payload: bundle.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('400')
  end

  it 'fails when $inquire response did not contain response Bundle' do
    bundle = request_bundle('AUTH-0001')
    stub_inquire(
      {
        resourceType: 'Parameters',
        parameter: []
      }.to_json
    )

    result = run(
      test,
      server_endpoint:,
      must_support_pa_inquire_request_payload: bundle.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'The $inquire response did not contain a response Bundle.'
    )
  end

  it 'fails when $inquire response did not contain response Bundle or Paramter' do
    bundle = request_bundle('AUTH-0001')
    stub_inquire(
      {
        resourceType: 'OperationOutcome'
      }.to_json
    )

    result = run(
      test,
      server_endpoint:,
      must_support_pa_inquire_request_payload: bundle.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      '$inquire response is neither Parameters or Bundle'
    )
  end
end
