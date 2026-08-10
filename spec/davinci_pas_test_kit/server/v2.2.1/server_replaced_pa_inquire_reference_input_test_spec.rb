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
      pa_inquire_request_body: bundle.to_json
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to include(
      'inquiry requests did not contain an authorization number'
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
      pa_inquire_request_body: bundle.to_json
    )

    expect(result.result).to eq('pass')
  end
end
