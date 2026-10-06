require_relative 'request_count_gating'

module DaVinciPASTestKit
  module ClientBundleValidationHelper
    include RequestCountGating

    ###########################################################################
    # Tags and Request Loading
    ###########################################################################
    def request_type_tag
      case operation_name
      when 'inquire'
        INQUIRE_TAG
      when 'submit'
        SUBMIT_TAG
      else
        raise Inferno::Exceptions::TestSuiteImplementationException.new(
          'PAS Client Bundle Validation Test',
          "invalid operation name #{operation_name}"
        )
      end
    end

    def workflow_tag
      config.options[:workflow_tag]
    end

    # workflow_tag may be a single tag or an Array of tags; normalized to an Array so fetch_requests
    # doesn't need its own is_a?(Array) check.
    def workflow_tags
      Array(workflow_tag)
    end

    def fetch_requests
      tags = workflow_tags.presence || [nil]
      tags.flat_map { |tag| load_tagged_requests(*[request_type_tag, tag].compact) }
    end

    ###########################################################################
    # Request Count
    ###########################################################################

    # Raises if there are multiple requests and the test doesn't allow that.
    # Skips if there are no requests and the test doesn't allow that.
    # @param requests [Array<Inferno::Entities::Request>] the requests loaded for this test.
    # @param description [String] identifies the requests in the raised message, e.g.
    #   "submit requests".
    def check_request_count(requests, description)
      if requests.length > 1 && !multiple_requests_ok?
        raise Inferno::Exceptions::TestSuiteImplementationException.new(
          'multiple request handling',
          "#{requests.length} #{description} were tagged for validation by this test, which does not expect " \
          'more than one.'
        )
      elsif requests.empty?
        if no_requests_ok?
          pass "No #{description} analyzed."
        else
          skip "No #{description} received."
        end
      end
    end

    ###########################################################################
    # Extraction logic
    ###########################################################################

    def message_contents(request)
      case message_direction_name
      when 'request'
        request.request_body
      when 'response'
        request.response_body
      else
        raise Inferno::Exceptions::TestSuiteImplementationException.new(
          'PAS Client Bundle Validation Test',
          "invalid message direction name #{message_direction_name}"
        )
      end
    end

    def parameters_target_parameter_name
      case message_direction_name
      when 'request'
        'resource'
      when 'response'
        'return'
      else
        raise Inferno::Exceptions::TestSuiteImplementationException.new(
          'PAS Client Bundle Validation Test',
          "invalid message direction name #{message_direction_name}"
        )
      end
    end

    ###########################################################################
    # Validation logic
    ###########################################################################

    # Finds Bundles in the requests and determines which ones are non-conformant.
    #
    # Assumes this is the only thing logging to `messages` during this run and that it's
    # called at most once, so every message present afterward is one it logged itself.
    def non_conformant_bundles
      requests = fetch_requests
      check_request_count(requests, "$#{operation_name} #{message_direction_name}s")
      requests.each_with_index { |request, index| validate_request(request, index) }

      messages
        .select { |message| message[:type] == 'error' }
        .map { |message| message[:message].split(':', 2).first }
        .uniq
    end

    # Validates one request/response, extracting and checking the Bundle(s) it contains and
    # logging any problem found along the way - this only logs, callers determine what failed
    # from `messages` afterward (see non_conformant_bundles).
    def validate_request(request, index)
      message_label = entity_label("#{message_direction_name.capitalize} #{index + 1}")
      contents = message_contents(request)
      message_resource = resource_from_message_contents(contents, message_label)
      return if message_resource.blank?

      # extraction varies - provided by test class if not using the default. May contain nil
      # placeholders for positions that held something other than a Bundle (already reported),
      # so Bundle labels keep their original position.
      bundles = bundles_from_message_resource(message_resource, message_label)

      if bundles.length > 1
        bundles.each_with_index do |bundle, bundle_index|
          next if bundle.nil?

          bundle_label = entity_label("#{message_label.delete_suffix(':')} Bundle #{bundle_index + 1}")
          bundle_has_errors?(bundle, bundle_label)
        end
      else
        bundles.compact.each { |bundle| bundle_has_errors?(bundle, message_label) }
      end
    end

    # A label identifying one request/response, or a Bundle within one, for use as a message
    # prefix. Always ends in ':' so a logged message's entity can be recovered by splitting on
    # its first ':' - see non_conformant_bundles.
    def entity_label(description)
      "#{description}:"
    end

    def resource_from_message_contents(contents, label)
      resource = FHIR.from_contents(contents)
      messages << { type: 'error', message: "#{label} Not a FHIR resource." } unless resource.present?
      resource
    rescue StandardError
      messages << { type: 'error', message: "#{label} Invalid JSON." }
      nil
    end

    # standard Bundle extraction: 1 Bundle, not wrapped in Parameters
    def bundles_from_message_resource(message_resource, message_label)
      case message_resource
      when FHIR::Bundle
        [message_resource]
      when FHIR::Parameters
        messages << { type: 'error',
                      message: "#{message_label} expected a Bundle resource, got Parameters." }
        target_parameter_name = parameters_target_parameter_name
        matching_resources = extract_resources_from_parameters(message_resource, target_parameter_name)

        if matching_resources.empty?
          messages << { type: 'error',
                        message: "#{message_label} Parameters resource had no Bundle " \
                                 "in a '#{target_parameter_name}' entry." }
          []
        elsif matching_resources.length > 1
          messages << { type: 'error',
                        message: "#{message_label} Parameters resource had multiple '#{target_parameter_name}' " \
                                 'entries, but only one allowed (Bundles not validated).' }
          []
        elsif matching_resources.first.is_a?(FHIR::Bundle)
          [matching_resources.first]
        else
          messages << { type: 'error',
                        message: "#{message_label} Parameters resource '#{target_parameter_name}' entry expected to " \
                                 "contain a Bundle, got #{matching_resources.first&.resourceType}" }
          []
        end

      else
        messages << { type: 'error',
                      message: "#{message_label} expected a Bundle resource, got #{message_resource.resourceType}." }
        []
      end
    end

    def bundle_has_errors?(bundle, label)
      bundle_messages = perform_bundle_validation(bundle, operation_name, message_direction_name, ig_version)
      bundle_messages.each { |m| messages << { type: m[:type], message: "#{label} #{m[:message]}" } }
      bundle_messages.any? { |m| m[:type] == 'error' }
    rescue NoMethodError, TypeError, ArgumentError => e
      # a malformed Bundle (e.g., an entry with no resource) shouldn't stop the remaining
      # requests/Bundles from being validated
      messages << { type: 'error', message: "#{label} could not be validated: #{e.message}" }
      true
    end
  end
end
