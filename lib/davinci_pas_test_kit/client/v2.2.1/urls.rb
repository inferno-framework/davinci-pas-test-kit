# frozen_string_literal: true

require_relative '../client_urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    module URLs
      include ClientURLs

      def suite_id
        DaVinciPASTestKit::DaVinciPASV221::ClientSuite.id
      end
    end
  end
end
