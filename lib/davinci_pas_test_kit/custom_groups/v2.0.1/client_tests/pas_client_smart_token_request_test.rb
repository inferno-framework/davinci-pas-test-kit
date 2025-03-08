require 'jwt'
require_relative '../../../tags'
require_relative '../../../urls'
require_relative '../../../endpoints/mock_udap_smart_server'

module DaVinciPASTestKit
  module DaVinciPASV201
    class PASClientSMARTTokenRequestTest < Inferno::Test
      include URLs

      id :pas_client_v201_smart_token_request_test
      title 'Verify SMART Token Requests'
      description %(
        Check that SMART token requests are conformant.
      )

      input :client_id,
            optional: true,
            locked: true
      input :jwk_set,
            optional: true,
            locked: true,
            description: %(
              JWK Set to use when validating client assertions. Run the Client Registration group
              to populate.
            )

      run do
        omit_if jwk_set.blank?, 'SMART backend services auth not demonstrated as a part of this test session.'

        load_tagged_requests(TOKEN_TAG, SMART_TAG)
        skip_if requests.blank?, 'No SMART token requests made.'

        jti_list = []
        requests.each_with_index do |token_request, index|
          request_params = URI.decode_www_form(token_request.request_body).to_h
          check_request_params(request_params, index)
          check_client_assertion(request_params['client_assertion'], index, jti_list, token_request.url)
        end

        assert messages.none? { |msg|
          msg[:type] == 'error'
        }, 'Invalid token requests detected. See messages for details.'
      end

      def check_request_params(params, index)
        if params['grant_type'] != 'client_credentials'
          add_message('error',
                      "Token request #{index} had an incorrect `grant_type`: expected 'client_credentials', " \
                      "but got '#{params['grant_type']}'")
        end
        if params['client_assertion_type'] != 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
          add_message('error',
                      "Token request #{index} had an incorrect `client_assertion_type`: " \
                      "expected 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer', " \
                      "but got '#{params['client_assertion_type']}'")
        end
        return unless params['scope'].blank?

        add_message('error', "Token request #{index} did not include the requested `scope`")
      end

      def check_client_assertion(assertion, index, jti_list, endpoint_aud)
        decoded_token =
          begin
            JWT::EncodedToken.new(assertion)
          rescue StandardError => e
            add_message('error', "Token request #{index} contained an invalid client assertion jwt: #{e}")
            nil
          end

        return unless decoded_token.present?

        check_jwt_header(decoded_token.header, index)
        check_jwt_payload(decoded_token.payload, index, jti_list, endpoint_aud)
        check_jwt_signature(decoded_token, index)
      end

      def check_jwt_header(header, index)
        return unless header['typ'] != 'JWT'

        add_message('error', "client assertion jwt on token request #{index} has an incorrect `typ` header: " \
                             "expected 'JWT', got '#{header['typ']}'")
      end

      def check_jwt_payload(claims, index, jti_list, endpoint_aud)
        if claims['iss'] != client_id
          add_message('error', "client assertion jwt on token request #{index} has an incorrect `iss` claim: " \
                               "expected '#{client_id}', got '#{claims['iss']}'")
        end

        if claims['sub'] != client_id
          add_message('error', "client assertion jwt on token request #{index} has an incorrect `sub` claim: " \
                               "expected '#{client_id}', got '#{claims['sub']}'")
        end

        if claims['aud'] != endpoint_aud
          add_message('error', "client assertion jwt on token request #{index} has an incorrect `aud` claim: " \
                               "expected '#{endpoint_aud}', got '#{claims['aud']}'")
        end

        if claims['exp'].blank?
          add_message('error', "client assertion jwt on token request #{index} is missing the `exp` claim.")
        end

        if claims['jti'].blank?
          add_message('error', "client assertion jwt on token request #{index} is missing the `jti` claim.")
        elsif jti_list.include?(claims['jti'])
          add_message('error', "client assertion jwt on token request #{index} has a `jti` claim that was " \
                               "previouly used: '#{claims['jti']}'.")
        else
          jti_list << claims['jti']
        end
      end

      def check_jwt_signature(encoded_token, index)
        error_prefix = "Signature validation failed on token request #{index}:"

        if encoded_token.header['alg'].blank?
          add_message('error', "#{error_prefix} no `alg` header to use for signature validation.")
          return
        end
        if encoded_token.header['kid'].blank?
          add_message('error', "#{error_prefix} no `kid` header to idenitfy the JWK for signature validation.")
          return
        end

        jwk = identify_key(encoded_token.header['kid'], encoded_token.header['jku'])
        if jwk.blank?
          add_message('error', "#{error_prefix} no key found with `kid` '#{encoded_token.header['kid']}'")
          return
        end

        begin
          encoded_token.verify_signature!(algorithm: encoded_token.header['alg'], key: jwk.verify_key)
        rescue StandardError => e
          add_message('error', "#{error_prefix} invalid signature - #{e}")
        end
      end

      def identify_key(kid, jku)
        key_set = jku.present? ? jku : jwk_set
        parsed_key_set = MockUdapSmartServer.jwk_set(key_set)
        parsed_key_set.find { |key| key.kid == kid }
      end
    end
  end
end
