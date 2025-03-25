require_relative '../../../lib/davinci_pas_test_kit/tags'

RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PASClientRegistrationSMARTVerification do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:test) { described_class }
  let(:jwks_valid) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'smart_jwks.json'))
  end
  let(:jwks_url_valid) { 'https://inferno.healthit.gov/suites/custom/smart_stu2/.well-known/jwks.json' }

  it 'omits if not configured for smart' do
    result = run(test)
    expect(result.result).to eq('omit')
  end

  it 'passes for a valid raw jwks' do
    result = run(test, smart_jwk_set: jwks_valid)
    expect(result.result).to eq('pass')
  end

  it 'passes for a valid jwks uri' do
    stub_request(:get, jwks_url_valid)
      .to_return(status: 200, body: jwks_valid)

    result = run(test, smart_jwk_set: jwks_url_valid)
    expect(result.result).to eq('pass')
  end

  it 'fails for an invalid jwks uri' do
    stub_request(:get, jwks_url_valid)
      .to_return(status: 404)

    result = run(test, smart_jwk_set: jwks_url_valid)
    expect(result.result).to eq('fail')
  end
end
