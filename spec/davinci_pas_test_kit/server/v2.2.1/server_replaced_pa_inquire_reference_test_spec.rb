RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASServerReplacedPAInquireReferenceTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v221' }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:input_test) do
    DaVinciPASTestKit::DaVinciPASV221::PASServerReplacedPAInquireReferenceInputTest
  end

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
                    url: described_class::AUTHORIZATION_NUMBER_EXTENSION,
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
                          url: described_class::AUTHORIZATION_NUMBER_EXTENSION,
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

  def stub_inquire(response_body)
    stub_request(:post, "#{server_endpoint}/Claim/$inquire")
      .to_return(status: 200, body: response_body)
  end

  it 'fails when provided request body does not contain a reference number' do
    bundle = request_bundle('')

    result = run(
      input_test,
      pa_inquire_request_body: bundle.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('inquiry requests did not contain an authorization number')
  end

  it 'passes with a JSON Bundle when the response contains a different reference number' do
    bundle = request_bundle('AUTH-0001')
    stub_inquire(response_parameters('AUTH-0002'))

    result = run(
      test,
      server_endpoint:,
      pa_inquire_request_body: bundle.to_json
    )

    expect(result.result).to eq('pass')
  end

  it 'submits every Bundle when provided a list of Bundles' do
    bundle = request_bundle('AUTH-0001')
    stub_inquire(response_parameters('AUTH-0002'))

    result = run(
      test,
      server_endpoint:,
      pa_inquire_request_body: [bundle].to_json
    )

    expect(result.result).to eq('pass')
  end

  it 'fails when the response contains the same reference number' do
    bundle = request_bundle('AUTH-0001')
    stub_inquire(response_parameters('AUTH-0001'))

    result = run(
      test,
      server_endpoint:,
      pa_inquire_request_body: bundle.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('different authorization number')
  end
end
