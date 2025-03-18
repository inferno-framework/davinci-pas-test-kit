require_relative '../../../lib/davinci_pas_test_kit/tags'

RSpec.describe DaVinciPASTestKit::MockUdapSmartServer, :request, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'davinci_pas_client_suite_v201' }
  let(:test) { suite.children[2].children[0].children[0] }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:dummy_result) { repo_create(:result, test_session_id: test_session.id) }
  let(:client_id) { 'cid' }
  let(:jwks_valid) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'smart_jwks.json'))
  end
  let(:parsed_jwks) { JWT::JWK::Set.new(JSON.parse(jwks_valid)) }
  let(:token_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::TOKEN_PATH}" }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  let(:submit_request_json) do
    JSON.parse(File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json')))
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
      iss: 'cid',
      sub: 'cidy',
      aud: 'https://inferno-qa.healthit.gov/suites/custom/davinci_pas_v201_client/auth/token'
    }
  end
  let(:client_assertion_sig_valid) { make_jwt(payload_invalid, header_invalid, 'RS384', parsed_jwks.keys[3]) }
  let(:client_assertion_sig_invalid) { "#{make_jwt(payload_invalid, header_invalid, 'RS384', parsed_jwks.keys[3])}bad" }
  let(:token_request_body_sig_invalid) do
    { grant_type: 'invalid',
      client_assertion_type: 'invalid',
      client_assertion: client_assertion_sig_invalid }
  end
  let(:token_request_body_sig_valid) do
    { grant_type: 'invalid',
      client_assertion_type: 'invalid',
      client_assertion: client_assertion_sig_valid }
  end
  let(:udap_client_id) { 'aHR0cDovL2xvY2FsaG9zdDo0NTY3L2N1c3RvbS9nMzNfdGVzdF9zdWl0ZS9maGly' }
  let(:udap_payload_invalid) do
    {
      iss: udap_client_id,
      sub: 'different',
      aud: 'http://localhost:4567/custom/davinci_pas_client_suite_v201/auth/token',
      exp: 60.minutes.from_now.to_i,
      iat: Time.now.to_i,
      jti: '96a86a90d27090e8ab3835403fb64fec973977a63d7af5e7cf99064d6bb32092',
      extensions: '{"hl7-b2b":{"version":"1","subject_name":"UDAP Test Kit","organization_name":"Inferno Framework","organization_id":"https://inferno-framework.github.io/","purpose_of_use":["SYSDEV"]}}' # rubocop:disable Layout/LineLength
    }
  end
  let(:root_cert) do
    File.read(File.join(__dir__, '..', '..', '..', 'lib', 'davinci_pas_test_kit', 'certs', 'infernoCA.pem'))
  end
  let(:root_key) do
    File.read(File.join(__dir__, '..', '..', '..', 'lib', 'davinci_pas_test_kit', 'certs', 'infernoCA.key'))
  end
  let(:leaf_cert) do
    File.read(File.join(__dir__, '..', '..', '..', 'lib', 'davinci_pas_test_kit', 'certs', 'TestKit.pem'))
  end
  let(:leaf_key) do
    File.read(File.join(__dir__, '..', '..', '..', 'lib', 'davinci_pas_test_kit', 'certs', 'TestKitPrivateKey.key'))
  end
  let(:udap_reg_request_valid) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'udap_reg_request_valid.json'))
  end
  let(:udap_assertion_correct_cert) do
    UDAPSecurityTestKit::UDAPJWTBuilder.encode_jwt_with_x5c_header(
      udap_payload_invalid,
      leaf_key,
      'RS256',
      [leaf_cert]
    )
  end
  let(:udap_assertion_wrong_cert) do
    UDAPSecurityTestKit::UDAPJWTBuilder.encode_jwt_with_x5c_header(
      udap_payload_invalid,
      root_key,
      'RS256',
      [root_cert]
    )
  end
  let(:udap_token_request_body_sig_invalid) do
    { grant_type: 'invalid',
      client_assertion_type: 'invalid',
      client_assertion: "#{udap_assertion_correct_cert}bad",
      udap: 1 }
  end
  let(:udap_token_request_body_sig_valid) do
    { grant_type: 'invalid',
      client_assertion_type: 'invalid',
      client_assertion: udap_assertion_correct_cert,
      udap: 1 }
  end
  let(:udap_token_request_body_wrong_cert) do
    { grant_type: 'invalid',
      client_assertion_type: 'invalid',
      client_assertion: udap_assertion_wrong_cert,
      udap: 1 }
  end

  def make_jwt(payload, header, alg, jwk)
    token = JWT::Token.new(payload:, header:)
    token.sign!(algorithm: alg, key: jwk.signing_key)
    token.jwt
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

  describe 'when generating token responses for SMART' do
    it 'returns 401 when the signature is bad or cannot be verified' do
      inputs = { client_id:, jwk_set: jwks_valid }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(token_url, token_request_body_sig_invalid)
      expect(last_response.status).to eq(401)
      error_body = JSON.parse(last_response.body)
      expect(error_body['error']).to eq('invalid_client')
      expect(error_body['error_description']).to match(/Signature verification failed/)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end

    it 'returns 200 when the signature is correct even if header is bad' do
      inputs = { client_id:, jwk_set: jwks_valid }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(token_url, token_request_body_sig_valid)
      expect(last_response.status).to eq(200)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end
  end

  describe 'when generating token responses for UDAP' do
    it 'returns 401 when the signature is invalid' do
      create_reg_request(udap_reg_request_valid)
      inputs = { client_id: udap_client_id }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(token_url, udap_token_request_body_sig_invalid)
      expect(last_response.status).to eq(401)
      expect(last_response.body).to match(/Signature verification failed/)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end

    it 'returns 401 when the signatured used a cert that was not registered' do
      create_reg_request(udap_reg_request_valid)
      inputs = { client_id: udap_client_id }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(token_url, udap_token_request_body_wrong_cert)
      expect(last_response.status).to eq(401)
      expect(last_response.body).to match(/signing cert does not match registration cert/)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end

    it 'returns 200 when no prior registration' do
      inputs = { client_id: udap_client_id }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(token_url, udap_token_request_body_sig_valid)
      expect(last_response.status).to eq(200)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end

    it 'returns 200 when signature valid even if other issues' do
      create_reg_request(udap_reg_request_valid)
      inputs = { client_id: udap_client_id }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      post_json(token_url, udap_token_request_body_sig_valid)
      expect(last_response.status).to eq(200)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end
  end

  describe 'when responding to access requests' do
    it 'returns 401 when the access token has expired' do
      expired_token = Base64.strict_encode64({
        client_id:,
        expiration: 1,
        nonce: SecureRandom.hex(8)
      }.to_json)

      inputs = { client_id:, jwk_set: jwks_valid }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{expired_token}")
      post_json(submit_url, submit_request_json)
      expect(last_response.status).to eq(401)

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end

    it 'returns 200 when the access token has not expired' do
      exp_timestamp = Time.now.to_i

      unexpired_token = Base64.strict_encode64({
        client_id:,
        expiration: exp_timestamp,
        nonce: SecureRandom.hex(8)
      }.to_json)

      allow(Time).to receive(:now).and_return(Time.at(exp_timestamp - 10))

      inputs = { client_id:, jwk_set: jwks_valid }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{unexpired_token}")
      post_json(submit_url, submit_request_json)
      expect(last_response.status).to eq(200)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'returns 200 when the decoded access token has no expiration' do
      token_no_exp = Base64.strict_encode64({
        client_id:,
        nonce: SecureRandom.hex(8)
      }.to_json)

      inputs = { client_id:, jwk_set: jwks_valid }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header('Authorization', "Bearer #{token_no_exp}")
      post_json(submit_url, submit_request_json)
      expect(last_response.status).to eq(200)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end
  end
end
