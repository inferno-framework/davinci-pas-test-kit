# frozen_string_literal: true

require_relative '../client_urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    module URLs
      include ClientURLs

      def suite_id
        DaVinciPASTestKit::DaVinciPASV201::ClientSuite.id
      end
    end
  end
end
