module Inferno
  module DSL
    class FHIRClientBuilder
      def build(runnable, block)
        self.runnable = runnable
        instance_exec(self, &block)

        FHIR::Client.new(url).tap do |client|
          client.additional_headers = headers if headers
          client.default_json
          client.set_bearer_token bearer_token if bearer_token
          oauth_credentials&.add_to_client(client)
          client.set_basic_auth(basic_id, basic_password) if basic_id && basic_password
        end
      end

      def basic_id(basic_id = nil)
        @basic_id ||=
          if basic_id.is_a? Symbol
            runnable.send(basic_id)
          else
            basic_id
          end
      end

      def basic_password(basic_password = nil)
        @basic_password ||=
          if basic_password.is_a? Symbol
            runnable.send(basic_password)
          else
            basic_password
          end
      end
    end
  end
end
