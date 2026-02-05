require_relative '../../cross_suite/base_urls'

module DaVinciPASTestKit
  module DaVinciPASV220
    module ServerURLs
      include BaseURLs

      def suite_id
        DaVinciPASTestKit::DaVinciPASV220::ServerSuite.id
      end
    end
  end
end
