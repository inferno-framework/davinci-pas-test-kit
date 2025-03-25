require_relative '../../../lib/davinci_pas_test_kit/tags'

RSpec.describe DaVinciPASTestKit::DaVinciPASV201::PASClientSMARTTokenRequestTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:test) { described_class }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:dummy_result) { repo_create(:result, test_session_id: test_session.id) }
  let(:client_id) { 'cid' }
  let(:jwks_valid) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'smart_jwks.json'))
  end
  let(:parsed_jwks) { JWT::JWK::Set.new(JSON.parse(jwks_valid)) }
  let(:jwks_url_valid) { 'https://inferno.healthit.gov/suites/custom/smart_stu2/.well-known/jwks.json' }
  let(:token_endpoint) { 'https://inferno.healthit.gov/suites/custom/davinci_pas_v201_client/auth/token' }
  let(:header_valid) do
    {
      typ: 'JWT',
      alg: 'RS384',
      kid: 'b41528b6f37a9500edb8a905a595bdd7'
    }
  end
  let(:payload_valid) do
    {
      iss: 'cid',
      sub: 'cid',
      aud: 'https://inferno.healthit.gov/suites/custom/davinci_pas_v201_client/auth/token',
      exp: 1741398050,
      jti: 'random-non-reusable-jwt-id-123'
    }
  end
  let(:client_assertion_valid) { make_jwt(payload_valid, header_valid, 'RS384', parsed_jwks.keys[3]) }
  let(:token_request_body_valid) do
    { grant_type: 'client_credentials',
      scope: 'system/*.rs',
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion: client_assertion_valid }
  end
  let(:header_invalid) do
    {
      typ: 'JWTX',
      alg: 'RS384',
      kid: 'b41528b6f37a9500edb8a905a595bdd7'
    }
  end
  let(:payload_invalid) do
    {
      iss: 'cidx',
      sub: 'cidy',
      aud: 'https://inferno-qa.healthit.gov/suites/custom/davinci_pas_v201_client/auth/token'
    }
  end
  let(:client_assertion_invalid) { "#{make_jwt(payload_invalid, header_invalid, 'RS384', parsed_jwks.keys[3])}bad" }
  let(:token_request_body_invalid) do
    { grant_type: 'invalid',
      client_assertion_type: 'invalid',
      client_assertion: client_assertion_invalid }
  end
  let(:encoded_header_no_alg) { 'eyJ0eXAiOiJKV1QiLCJraWQiOiJiNDE1MjhiNmYzN2E5NTAwZWRiOGE5MDVhNTk1YmRkNyJ9' }

  def make_jwt(payload, header, alg, jwk)
    token = JWT::Token.new(payload:, header:)
    token.sign!(algorithm: alg, key: jwk.signing_key)
    token.jwt
  end

  def create_token_request(body)
    repo_create(
      :request,
      direction: 'incoming',
      url: token_endpoint,
      result: dummy_result,
      test_session_id: test_session.id,
      request_body: URI.encode_www_form(body),
      status: 200,
      tags: [DaVinciPASTestKit::TOKEN_TAG, DaVinciPASTestKit::SMART_TAG]
    )
  end

  it 'omits if not configured for auth' do
    result = run(test)
    expect(result.result).to eq('omit')
  end

  it 'skips if no token requests' do
    result = run(test, client_id:, smart_jwk_set: jwks_valid)
    expect(result.result).to eq('skip')
  end

  it 'passes for a valid request' do
    create_token_request(token_request_body_valid)
    result = run(test, client_id:, smart_jwk_set: jwks_valid)
    expect(result.result).to eq('pass')
  end

  it 'fails for an invalid request' do
    create_token_request(token_request_body_invalid)
    result = run(test, client_id:, smart_jwk_set: jwks_valid)
    expect(result.result).to eq('fail')
    result_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
    expect(result_messages.find { |m| /incorrect `grant_type`/.match(m.message) }).to_not be_nil
    expect(result_messages.find { |m| /incorrect `client_assertion_type`/.match(m.message) }).to_not be_nil
    expect(result_messages.find { |m| /did not include the requested `scope`/.match(m.message) }).to_not be_nil
    expect(result_messages.find { |m| /incorrect `typ` header/.match(m.message) }).to_not be_nil
    expect(result_messages.find { |m| /incorrect `iss` claim/.match(m.message) }).to_not be_nil
    expect(result_messages.find { |m| /incorrect `sub` claim/.match(m.message) }).to_not be_nil
    expect(result_messages.find { |m| /missing the `exp` claim/.match(m.message) }).to_not be_nil
    expect(result_messages.find { |m| /missing the `jti` claim/.match(m.message) }).to_not be_nil
    expect(result_messages.find { |m| /Signature verification failed/.match(m.message) }).to_not be_nil
  end

  it 'fails for an invalid request with no alg header' do
    token_request_body_valid[:client_assertion] =
      "#{encoded_header_no_alg}.#{client_assertion_valid.split('.')[1..].join('.')}"
    create_token_request(token_request_body_valid)
    result = run(test, client_id:, smart_jwk_set: jwks_valid)
    expect(result.result).to eq('fail')
    result_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
    expect(result_messages.find { |m| /missing `alg` header/.match(m.message) }).to_not be_nil
  end

  it 'fails for an invalid request with no kid header' do
    header_valid.delete(:kid)
    token_request_body_valid[:client_assertion] = make_jwt(payload_valid, header_valid, 'RS384', parsed_jwks.keys[3])
    create_token_request(token_request_body_valid)
    result = run(test, client_id:, smart_jwk_set: jwks_valid)
    expect(result.result).to eq('fail')
    result_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
    expect(result_messages.find { |m| /missing `kid` header/.match(m.message) }).to_not be_nil
  end

  it 'fails when a jti value is used multiple times' do
    create_token_request(token_request_body_valid)
    create_token_request(token_request_body_valid)
    result = run(test, client_id:, smart_jwk_set: jwks_valid)
    expect(result.result).to eq('fail')
    result_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
    expect(result_messages.find { |m| /`jti` claim that was previouly used/.match(m.message) }).to_not be_nil
  end

  it 'passes when a valid jku is provided' do
    stub_request(:get, jwks_url_valid)
      .to_return(status: 200, body: jwks_valid)
    header_valid[:jku] = jwks_url_valid
    token_request_body_valid[:client_assertion] = make_jwt(payload_valid, header_valid, 'RS384', parsed_jwks.keys[3])
    create_token_request(token_request_body_valid)
    result = run(test, client_id:, smart_jwk_set: jwks_valid)
    expect(result.result).to eq('pass')
  end
end
