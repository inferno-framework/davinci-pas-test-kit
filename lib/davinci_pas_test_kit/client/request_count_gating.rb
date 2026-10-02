module DaVinciPASTestKit
  # Shared predicates for the no_requests_ok/multiple_requests_ok config options, used to gate
  # on how many tagged requests were found by AbstractResponseAttest's run block and by
  # ClientBundleValidationHelper#check_request_count.
  module RequestCountGating
    def no_requests_ok?
      config.options[:no_requests_ok]
    end

    def multiple_requests_ok?
      config.options[:multiple_requests_ok]
    end
  end
end
