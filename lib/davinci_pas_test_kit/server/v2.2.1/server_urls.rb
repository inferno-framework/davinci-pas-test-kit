require_relative '../../cross_suite/base_urls'

module DaVinciPASTestKit
  module DaVinciPASV221
    module ServerURLs
      include BaseURLs

      def suite_id
        DaVinciPASTestKit::DaVinciPASV221::ServerSuite.id
      end
    end
  end
end
