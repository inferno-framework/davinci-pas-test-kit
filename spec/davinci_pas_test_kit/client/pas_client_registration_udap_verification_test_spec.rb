require_relative '../../../lib/davinci_pas_test_kit/tags'

RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PASClientRegistrationUDAPVerification do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:test) { described_class }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:dummy_result) { repo_create(:result, test_session_id: test_session.id) }
  let(:udap_client_uri) { 'urn:test' }
  let(:reg_request_bad_aud) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'udap_reg_request_bad_aud.json'))
  end

  def create_reg_request(body)
    repo_create(
      :request,
      direction: 'incoming',
      url: 'test',
      result: dummy_result,
      test_session_id: test_session.id,
      request_body: body,
      status: 200,
      tags: [DaVinciPASTestKit::REGISTRATION_TAG, DaVinciPASTestKit::UDAP_TAG]
    )
  end

  it 'omits if not configured for udap' do
    result = run(test)
    expect(result.result).to eq('omit')
  end

  it 'skips if no registration requests' do
    result = run(test, udap_client_uri:)
    expect(result.result).to eq('skip')
  end

  it 'fails if the registration request has the wrong aud' do
    create_reg_request(reg_request_bad_aud)
    result = run(test, udap_client_uri:)
    expect(result.result).to eq('fail')
  end
end
