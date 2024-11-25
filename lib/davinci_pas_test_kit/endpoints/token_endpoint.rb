module DaVinciPASTestKit
  class TokenEndpoint < Inferno::DSL::SuiteEndpoint
    def test_run_identifier
      URI.decode_www_form(request.body.string).to_h['client_id']
    end

    def tags
      [AUTH_TAG]
    end

    def make_response
      # Placeholder for a more complete mock token endpoint
      response.status = 200
      response.format = :json
      response.body = { access_token: SecureRandom.hex, token_type: 'bearer', expires_in: 300 }.to_json
    end

    def update_result
      results_repo.update_result(result.id, 'pass')
    end
  end
end
