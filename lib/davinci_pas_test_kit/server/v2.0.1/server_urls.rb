require_relative '../../cross_suite/base_urls'

module DaVinciPASTestKit
  module DaVinciPASV201
    module ServerURLs
      include BaseURLs

      def suite_id
        DaVinciPASTestKit::DaVinciPASV201::ServerSuite.id
      end
    end
  end
end
