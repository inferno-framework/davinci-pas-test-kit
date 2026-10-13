# frozen_string_literal: true

require_relative '../parameters_helper'
require_relative 'validation_test'
require_relative 'pas_constants'
require_relative 'pas_datatype_constraints'
require_relative 'referenced_resource_presence_validation'
require_relative 'validator_configuration'

module DaVinciPASTestKit
  module PasBundleValidation
    include DaVinciPASTestKit::ValidationTest
    include DaVinciPASTestKit::PasDatatypeConstraints
    include DaVinciPASTestKit::ReferencedResourcePresenceValidation
    include ParametersHelper

    ###########################################################################
    # Public API
    ###########################################################################

    # @return [Array<Hash>] The messages (of every severity) found while validating this
    #   bundle, each a { type:, message: } hash. Callers that only care about failure should
    #   check for a message with type: 'error' rather than just whether this is present -
    #   see validation_messages.
    # @param validator [Symbol] the name of the FHIR resource validator to use for profile
    #   validation. Use perform_no_custom_extensions_validation for Bundles Inferno sends.
    # @param echoed_from [FHIR::Bundle, String, nil] the request Bundle the response answers. When
    #   given, entry resources echoed back from it that carry no extensions beyond those they had in
    #   it are validated with the :default validator rather than `validator`, since the extensions
    #   came from the system under test.
    def perform_bundle_validation(bundle, operation, type, ig_version, request_bundle = nil, validator: :default,
                                  echoed_from: nil)
      @validation_messages = []
      @profile_validator = validator
      @echoed_from_bundle = parse_bundle(echoed_from)
      target_profile = PASConstants.bundle_profile_url_for_operation_and_type(operation, type)
      request_type = "#{operation}_#{type}"
      if type == 'request'
        perform_request_validation(bundle, target_profile, ig_version.delete_prefix('v'), request_type)
      else
        perform_response_validation(bundle, target_profile, ig_version.delete_prefix('v'), request_type, request_bundle)
      end
      validation_messages
    end

    # Validates a Bundle that Inferno sends to the system under test, which may be tester-provided,
    # using NO_CUSTOM_EXTENSIONS_VALIDATOR so that custom extensions aren't allowed. Resources echoed
    # back from the system under test's Bundle may keep the extensions they had in it.
    # @param type [String] 'request' or 'response' - see perform_bundle_validation.
    # @param echoed_from [FHIR::Bundle, String, nil] the Bundle from the system under test that this
    #   one answers, e.g. the request for a response, or nil if there is none - see
    #   perform_bundle_validation.
    # @return [Array<Hash>] see perform_bundle_validation.
    def perform_no_custom_extensions_validation(bundle, operation, type, ig_version, echoed_from:)
      perform_bundle_validation(bundle, operation, type, ig_version,
                                validator: NO_CUSTOM_EXTENSIONS_VALIDATOR, echoed_from:)
    end

    # Validates a Parameters resource that Inferno sends to wrap Bundles (e.g., a v2.2.1 $inquire
    # response) against the base Parameters definition, since PAS doesn't profile it, using
    # NO_CUSTOM_EXTENSIONS_VALIDATOR. Issues within the wrapped resources are dropped, since those are
    # validated separately - see perform_no_custom_extensions_validation.
    # @param parameters [FHIR::Parameters]
    # @return [Array<Hash>] the messages found, each a { type:, message: } hash.
    def perform_no_custom_extensions_parameters_validation(parameters)
      response_details = []
      resource_is_valid?(resource: parameters, validator: NO_CUSTOM_EXTENSIONS_VALIDATOR,
                         add_messages_to_runnable: false,
                         validator_response_details: response_details)
      validator_issues_to_messages(response_details.reject do |issue|
        issue.filtered || issue.location&.match?(/\AParameters\.parameter\[\d+\](\.part\[\d+\])*\.resource/)
      end)
    end

    ###########################################################################
    # Internal Validation Methods
    ###########################################################################

    # Every message (of every severity, not just errors) collected while validating the
    # current bundle. Passing-profile messages and per-issue profile-conformance messages
    # (see validate_bundle_entries_against_profiles) may be warnings or info, not just
    # errors, which is why this isn't error-only despite most entries being added via
    # add_validation_error.
    def validation_messages
      @validation_messages ||= []
    end

    # Appends a plain error string to validation_messages as a { type:, message: } hash,
    # for the many checks in this file that only ever produce errors (as opposed to
    # validate_bundle_entries_against_profiles, which already has typed messages from the
    # validator and concats them directly).
    def add_validation_error(message)
      validation_messages << { type: 'error', message: }
    end

    # The name of the FHIR resource validator used for profile validation of the current
    # bundle - see perform_bundle_validation.
    def profile_validator
      @profile_validator || :default
    end

    # How to validate one entry resource in the current bundle. Resources echoed back from the request
    # (see perform_bundle_validation's echoed_from) may keep the extensions they had in it: those that
    # add no extensions of their own use the :default validator, and the others use the specified
    # validator with the issues it reports about their echoed extensions dropped - see
    # echoed_extension_issue?.
    # @param full_url [String] the fullUrl of the entry containing the resource.
    # @param resource [FHIR::Model] the entry resource.
    # @return [Array(Symbol, Array)] the name of the validator to use, and the [element path, extension]
    #   pairs (see extensions_in) of the request resource the resource echoes, if any.
    def entry_validation_settings(full_url, resource)
      return [profile_validator, []] if profile_validator == :default

      request_entry = echoed_request_entry(full_url, resource)
      return [profile_validator, []] if request_entry.blank?

      echoed_extensions = extensions_in(validated_hash(request_entry.resource))
      all_echoed = extensions_in(validated_hash(resource)).all? { |extension| echoed_extensions.include?(extension) }
      [all_echoed ? :default : profile_validator, echoed_extensions]
    end

    def echoed_request_entry(full_url, resource)
      return if @echoed_from_bundle.blank?

      response_entry = FHIR::Bundle::Entry.new(fullUrl: full_url, resource:)
      @echoed_from_bundle.entry.find { |entry| echoed_resource?(entry, response_entry) }
    end

    # The resource as the validator receives it (Inferno sends its source_contents), as a hash. Unlike
    # to_hash, this keeps the extensions on primitive elements (e.g., `_birthDate`).
    def validated_hash(resource)
      JSON.parse(resource.source_contents)
    rescue StandardError
      resource.to_hash
    end

    # An extension is echoed if it appears, with the same content and at the same element path, in the
    # request resource. Paths leave out array indexes so reordered repeating elements still match.
    # Reference values are ignored because Inferno rewrites them when it echoes resources in responses
    # it generates.
    # @return [Array<Array(String, Hash)>] [element path, extension] pairs for every extension (at any
    #   depth, including modifierExtensions) in the value.
    def extensions_in(value, path = '')
      case value
      when Hash
        value.flat_map do |key, child|
          child_path = path.empty? ? key : "#{path}.#{key}"
          own = if %w[extension modifierExtension].include?(key)
                  Array(child).map { |extension| [child_path, without_references(extension)] }
                else
                  []
                end
          own + extensions_in(child, child_path)
        end
      when Array
        value.flat_map { |child| extensions_in(child, path) }
      else
        []
      end
    end

    def without_references(value)
      case value
      when Hash
        value.except('reference').transform_values { |child| without_references(child) }
      when Array
        value.map { |child| without_references(child) }
      else
        value
      end
    end

    # True if the validator issue is about an echoed extension, i.e., it is located at an extension that
    # is in echoed_extensions and its message names the extension's url, as the validator's message for
    # an extension not allowed by the strict validator does.
    # @param resource_hash [Hash] the validated resource, as a hash.
    def echoed_extension_issue?(issue, resource_hash, echoed_extensions)
      path, extension = extension_at_location(resource_hash, issue.location)
      return false if extension.blank? || extension['url'].blank?

      echoed_extensions.include?([path, without_references(extension)]) && issue.message.to_s.include?(extension['url'])
    end

    # Resolves a validator issue location such as `Patient.name[0].extension[1]` against the resource.
    # Extensions on primitive elements are located by the element's name (e.g.,
    # `Patient.birthDate.extension[0]`) but held in its `_` sibling (e.g., `_birthDate`) in JSON.
    # @return [Array(String, Hash), nil] the extension's index-free element path (as in extensions_in)
    #   and the extension, or nil if the location isn't an extension in the resource.
    def extension_at_location(resource_hash, location)
      value = resource_hash
      names = location.to_s.split('.').drop(1).map do |segment|
        name, index = segment.match(/\A(\w+)(?:\[(\d+)\])?\z/)&.captures
        return nil if name.nil? || !value.is_a?(Hash)

        name = "_#{name}" if primitive_element?(value, name)
        value = value[name]
        value = value[index.to_i] if index.present? && value.is_a?(Array)
        name
      end
      return unless %w[extension modifierExtension].include?(names.last) && value.is_a?(Hash)

      [names.join('.'), value]
    end

    # True if the element is a primitive (or repeating primitive) with a `_` sibling holding its
    # extensions, in the JSON object `parent`.
    def primitive_element?(parent, name)
      parent.key?("_#{name}") && Array.wrap(parent[name]).none?(Hash)
    end

    def parse_bundle(bundle)
      bundle = FHIR.from_contents(bundle) if bundle.is_a?(String)
      bundle if bundle.is_a?(FHIR::Bundle)
    rescue StandardError
      nil
    end

    def perform_request_validation(bundle, profile_url, version, request_type)
      validate_pa_request_payload_structure(bundle, request_type)
      validate_resources_conformance_against_profile(bundle, profile_url, version, request_type)
    end

    def perform_response_validation(response_bundle, profile_url, version, request_type, request_bundle = nil)
      validate_pa_response_body_structure(response_bundle, request_bundle) if request_type.start_with?('submit')
      validate_resources_conformance_against_profile(response_bundle, profile_url, version, request_type)
    end

    ###########################################################################
    # Structure Validation
    ###########################################################################

    # Validates the structure of a Prior Authorization (PA) request Bundle.
    #
    # @param bundle [FHIR::Bundle] The FHIR Bundle of the PA request.
    #
    # This method performs various checks on the PA request payload, including validating
    # the FHIR bundle structure, checking the resource type, and validating the resources
    # referenced in the Claim resource are included in the bundle. It ensures that the first
    # entry in the Bundle is a Claim resource and additional entries are populated
    # with referenced resources, following the traversal of references.
    # Duplicate resources are handled as required (appearing only once
    # in the bundle entry).
    def validate_pa_request_payload_structure(bundle, request_type)
      bundle_entry_resources = bundle.entry.map(&:resource)
      first_entry = bundle_entry_resources.first
      base_url = extract_base_url(bundle.entry.first&.fullUrl)

      check_presence_of_referenced_resources(first_entry, base_url, bundle.entry)
        .each { |msg| add_validation_error(msg) }

      # request_type is the compound 'submit_request' / 'inquire_request' built by
      # perform_bundle_validation - start_with? also accepts a bare 'submit', consistent with
      # find_profile_url and validate_resources_conformance_against_profile below.
      if request_type.start_with?('submit')
        unless first_entry.is_a?(FHIR::Claim)
          add_validation_error("[Bundle/#{bundle.id}]: The first bundle entry must be a Claim")
        end

        validate_uniqueness_of_supporting_info_sequences(first_entry)
        validate_bundle_entries_full_url(bundle)
      else
        claim_resource = bundle_entry_resources.find { |resource| resource&.resourceType == 'Claim' }
        if claim_resource.blank?
          add_validation_error("[Bundle/#{bundle.id}]: Claim must be present for inquiry request")
        end

        # The inquiry operation must contain a requesting provider organization,
        # a payer organization, and a patient for the inquiry
        patient_reference = claim_resource&.patient&.reference
        provider_reference = claim_resource&.provider&.reference
        payer_reference = claim_resource&.insurer&.reference

        if patient_reference.blank?
          add_validation_error("[Bundle/#{bundle.id}]: The Claim for inquiry operation must reference a patient.")
        end
        if provider_reference.blank?
          add_validation_error("[Bundle/#{bundle.id}]: The claim for inquiry operation must reference " \
                               'a requesting provider organization.')
        end
        if payer_reference.blank?
          add_validation_error("[Bundle/#{bundle.id}]: The Claim for inquiry operation must contain " \
                               'a payer organization.')
        end
      end
    end

    # Validates the response body structure of a Prior Authorization (PA) response.
    #
    # @param pa_response_bundle [FHIR::Bundle] The FHIR bundle representing the PA response.
    # @param pa_request_bundle [FHIR::Bundle, String, nil] The submitted PA request Bundle, either parsed or JSON.
    #
    # This method performs validation of the PA response bundle structure.
    # It follows the PAS IG requirement that the FHIR Bundle generated
    # from the response starts with a ClaimResponse entry.
    # For response of $submit request: Additional Bundle entries are populated
    # with resources referenced by the ClaimResponse
    # or descendant references, ensuring that only one resource is created for
    # a given combination of content. Resources echoed back from the request are validated
    # to ensure the same fullUrl and resource identifiers as in the
    # request are used.
    def validate_pa_response_body_structure(pa_response_bundle, pa_request_bundle)
      first_entry = pa_response_bundle.entry.first&.resource
      unless first_entry.is_a?(FHIR::ClaimResponse)
        add_validation_error("[Bundle/#{pa_response_bundle.id}]: The first bundle entry must be a ClaimResponse")
      end

      base_url = extract_base_url(pa_response_bundle.entry.last&.fullUrl)
      check_presence_of_referenced_resources(first_entry, base_url, pa_response_bundle.entry)
        .each { |msg| add_validation_error(msg) }

      validate_echoed_response_resources(pa_response_bundle, pa_request_bundle)
    end

    def validate_echoed_response_resources(pa_response_bundle, pa_request_bundle)
      return if pa_request_bundle.blank?

      request_bundle = pa_request_bundle.is_a?(FHIR::Bundle) ? pa_request_bundle : FHIR.from_contents(pa_request_bundle)
      return unless request_bundle.is_a?(FHIR::Bundle)

      pa_response_bundle.entry.each do |response_entry|
        response_resource = response_entry.resource
        next if response_resource.blank?

        request_entry = request_bundle.entry.find do |entry|
          echoed_resource?(entry, response_entry)
        end
        next if request_entry.blank?

        next if echoed_resource_identifiers_match?(request_entry, response_entry)

        add_validation_error(resource_present_in_pa_request_and_response_msg(response_resource))
      end
    rescue StandardError
      add_validation_error('Unable to compare PAS request and response Bundle resources for echoed identifiers.')
    end

    def echoed_resource?(request_entry, response_entry)
      request_resource = request_entry.resource
      response_resource = response_entry.resource
      return false if request_resource.blank? || response_resource.blank?
      return false unless request_resource.resourceType == response_resource.resourceType

      # True if any identifying field is present on both sides and matches, so we can later report if any
      # do not have all matching identifiers. Blank fields do not identify echoed resources.
      (request_entry.fullUrl.present? && request_entry.fullUrl == response_entry.fullUrl) ||
        (request_resource.id.present? && request_resource.id == response_resource.id) ||
        (identifiers_of(request_resource).present? &&
          identifiers_of(request_resource) == identifiers_of(response_resource))
    end

    def echoed_resource_identifiers_match?(request_entry, response_entry)
      request_resource = request_entry.resource
      response_resource = response_entry.resource

      request_entry.fullUrl == response_entry.fullUrl &&
        request_resource.id == response_resource.id &&
        identifiers_of(request_resource) == identifiers_of(response_resource)
    end

    # Nil for resource types without an identifier element (e.g., Binary, Parameters).
    def identifiers_of(resource)
      resource.identifier if resource.respond_to?(:identifier)
    end

    ###########################################################################
    # Bundle entry profile validation
    ###########################################################################

    # Profile conformance of Prior Authorization (PA) resources.
    #
    # @param bundle [FHIR::Bundle] The FHIR bundle representing the PA request/response.
    # @param profile_url [String] The URL of the FHIR profile to validate against.
    # @param version [String] The version of the profile.
    # @param request_type [String] the request operation: submit or inquiry
    #
    # This method performs conformance validation on the PA bundle and bundle entries.
    # The request/response bundle and includes resources are validated against their
    # respective profile.
    def validate_resources_conformance_against_profile(bundle, profile_url, version, request_type)
      reset_bundle_profile_inference_state
      add_resource_target_profile_to_map('bundle', bundle, profile_url)

      bundle_entry = bundle.entry

      root_entry = bundle_entry.find do |entry|
        ['Claim', 'ClaimResponse'].include?(entry.resource&.resourceType)
      end

      if root_entry.present?
        root_resource_profile_url = if %w[submit submit_request].include?(request_type) &&
                                       root_entry.resource.resourceType == 'Claim'
                                      determine_claim_submit_profile_url(version, root_entry.resource)
                                    else
                                      find_profile_url(request_type)[root_entry.resource.resourceType]
                                    end

        add_resource_target_profile_to_map(root_entry.fullUrl, root_entry.resource, root_resource_profile_url)
        extract_profiles_to_validate_each_entry(bundle_entry, root_entry, root_resource_profile_url, version)
      end

      add_us_core_profiles_to_unprofiled_entries(bundle_entry, version)
      validate_bundle_entries_against_profiles(version)
    end

    # Returns a hash map where the keys are resource full URLs and the values are a hash containing the resource
    # object and an array of associated profile URLs.
    # @return [Hash] The resource target profile map.
    def bundle_resources_target_profile_map
      @bundle_resources_target_profile_map ||= {}
    end

    # Adds a resource and its associated profile URL to the resource target profile map.
    # If the resource is already in the map, it adds the profile URL to the resource's list of profile URLs.
    # @param resource_full_url [String] The full URL of the resource.
    # @param resource [Object] The resource object.
    # @param profile_url [String] The profile URL to associate with the resource.
    def add_resource_target_profile_to_map(resource_full_url, resource, profile_url = nil)
      entry = bundle_resources_target_profile_map[resource_full_url] ||= { resource:, profile_urls: [] }

      return if profile_url.blank? || entry[:profile_urls].include?(profile_url)

      entry[:profile_urls] << profile_url
    end

    # Validates bundle resource and each entry in the bundle against its target profiles.
    # Validation messages are collected per profile rather than logged directly, so a
    # resource with multiple candidate profiles only reports errors when it fails all of
    # them. When a profile passes, only that profile's (non-error) messages are kept. Either
    # way, messages go into validation_messages rather than straight to the runnable's
    # `messages` - see perform_bundle_validation - so callers see every message this method
    # finds, not just the summary line for a resource that conformed to nothing.
    # @param version [String] The version of the IG.
    def validate_bundle_entries_against_profiles(version)
      bundle_resources_target_profile_map.each do |key, item|
        resource = item[:resource]
        base_profile = FHIR::Definitions.resource_definition(resource.resourceType).url
        validator, echoed_extensions = entry_validation_settings(key, resource) unless key == 'bundle'
        messages_by_profile = {}

        success_profile = item[:profile_urls].find do |url|
          profile_messages =
            if key == 'bundle'
              collect_bundle_profile_messages(resource, profile_url_for_validation(url, base_profile, version))
            elsif url == BASE_R4_PROFILE
              collect_resource_profile_messages(resource, validator:, echoed_extensions:)
            else
              collect_resource_profile_messages(resource, profile_url_for_validation(url, base_profile, version),
                                                validator:, echoed_extensions:) +
                datatype_constraint_messages(resource, profile_url_without_version(url), version)
            end
          messages_by_profile[url] = profile_messages
          profile_messages.none? { |message| message[:type] == 'error' }
        end

        if success_profile
          validation_messages.concat(messages_by_profile[success_profile])
        else
          messages_by_profile.each_value { |profile_messages| validation_messages.concat(profile_messages) }
          add_validation_error(generate_non_conformance_message(item))
        end
      end
    end

    def profile_url_for_validation(url, base_profile, version)
      url = url.to_s
      return url if url.include?('|') || profile_url_without_version(url) == base_profile
      return "#{url}|#{US_CORE_VERSION}" if us_core_profile_url?(url)

      "#{url}|#{version}"
    end

    def reset_bundle_profile_inference_state
      bundle_resources_target_profile_map.clear
      @bundle_entry_map = nil
    end

    def add_us_core_profiles_to_unprofiled_entries(bundle_entry, version)
      return unless us_core_profile_fallback_enabled?(version)

      bundle_entry.each do |entry|
        resource = entry.resource
        next if resource.blank?

        resource_full_url = resource_full_url_for_entry(entry)
        next if bundle_resources_target_profile_map[resource_full_url]&.dig(:profile_urls).present?

        profile_urls = us_core_profile_urls_for_resource(resource)
        profile_urls = [BASE_R4_PROFILE] if profile_urls.blank?

        profile_urls.each do |profile_url|
          add_resource_target_profile_to_map(resource_full_url, resource, profile_url)
        end
      end
    end

    def resource_full_url_for_entry(entry)
      resource = entry.resource

      entry.fullUrl.presence || "#{resource.resourceType}/#{resource.id}"
    end

    def us_core_profile_fallback_enabled?(version)
      version.to_s.delete_prefix('v').match?(/\A2\.2(\.|\z)/)
    end

    def us_core_profile_urls_for_resource(resource)
      profile_ids =
        case resource.resourceType
        when 'Condition'
          us_core_condition_profile_ids(resource)
        when 'DiagnosticReport'
          us_core_diagnostic_report_profile_ids(resource)
        when 'Observation'
          us_core_observation_profile_ids(resource)
        else
          Array(US_CORE_SINGLE_PROFILE_IDS_BY_RESOURCE[resource.resourceType])
        end

      us_core_profile_urls(profile_ids)
    end

    def us_core_condition_profile_ids(resource)
      if category_code_present?(resource, 'encounter-diagnosis', system: TERMINOLOGY_CONDITION_CATEGORY_SYSTEM)
        [US_CORE_CONDITION_ENCOUNTER_DIAGNOSIS_PROFILE_ID]
      else
        [US_CORE_CONDITION_PROBLEMS_HEALTH_CONCERNS_PROFILE_ID]
      end
    end

    def us_core_diagnostic_report_profile_ids(resource)
      if category_code_present?(resource, 'LAB', system: DIAGNOSTIC_REPORT_CATEGORY_SYSTEM)
        [US_CORE_DIAGNOSTIC_REPORT_LAB_PROFILE_ID]
      else
        [US_CORE_DIAGNOSTIC_REPORT_NOTE_PROFILE_ID]
      end
    end

    def us_core_observation_profile_ids(resource)
      code_profile_id = US_CORE_OBSERVATION_CODE_PROFILE_IDS.find do |code, _profile_id|
        codeable_concept_has_code?(resource.code, code, system: LOINC_SYSTEM)
      end&.last
      return [code_profile_id] if code_profile_id.present?

      profile_ids = []
      profile_ids << US_CORE_SMOKING_STATUS_PROFILE_ID if category_code_present?(resource, 'social-history',
                                                                                 system: OBSERVATION_CATEGORY_SYSTEM)
      profile_ids << US_CORE_VITAL_SIGNS_PROFILE_ID if category_code_present?(resource, 'vital-signs',
                                                                              system: OBSERVATION_CATEGORY_SYSTEM)
      if category_code_present?(resource, 'survey', system: OBSERVATION_CATEGORY_SYSTEM)
        profile_ids << US_CORE_OBSERVATION_SCREENING_ASSESSMENT_PROFILE_ID
      end
      # Keep candidate profiles most-specific first because validation stops at the first conformant profile.
      profile_ids << if category_code_present?(resource, 'laboratory', system: OBSERVATION_CATEGORY_SYSTEM)
                       US_CORE_OBSERVATION_LAB_PROFILE_ID
                     else
                       US_CORE_OBSERVATION_CLINICAL_RESULT_PROFILE_ID
                     end
      profile_ids << US_CORE_SIMPLE_OBSERVATION_PROFILE_ID
      profile_ids.uniq
    end

    def us_core_profile_urls(profile_ids)
      Array(profile_ids).map { |profile_id| "#{US_CORE_PROFILE_BASE}/#{profile_id}|#{US_CORE_VERSION}" }
    end

    def profile_url_without_version(url)
      url.to_s.split('|', 2).first
    end

    def us_core_profile_url?(url)
      profile_url_without_version(url).start_with?("#{US_CORE_PROFILE_BASE}/")
    end

    def category_code_present?(resource, code, system:)
      codeable_concept_has_code?(resource.category, code, system:)
    end

    def codeable_concept_has_code?(codeable_concepts, code, system:)
      systems = Array(system).compact
      Array(codeable_concepts).compact.any? do |codeable_concept|
        Array(codeable_concept&.coding).compact.any? do |coding|
          coding.code == code && systems.include?(coding.system)
        end
      end
    end

    # Validates a resource against a profile without logging, returning the unfiltered
    # issues as message hashes for the caller to log once profile selection is resolved.
    # @param resource [FHIR::Model] The resource to validate.
    # @param profile_url [String, nil] The profile URL (with version) to validate against,
    #   or nil to validate against the base resource definition.
    # @param validator [Symbol] The name of the FHIR resource validator to use.
    # @param echoed_extensions [Array] Extensions echoed from the request, whose issues are dropped - see
    #   entry_validation_settings.
    # @return [Array<Hash>] Message hashes for the issues found.
    def collect_resource_profile_messages(resource, profile_url = nil, validator: profile_validator,
                                          echoed_extensions: [])
      response_details = []
      resource_is_valid?(resource:, profile_url:, validator:,
                         add_messages_to_runnable: false,
                         validator_response_details: response_details)
      issues = response_details.reject(&:filtered)
      if echoed_extensions.present?
        resource_hash = validated_hash(resource)
        issues = issues.reject { |issue| echoed_extension_issue?(issue, resource_hash, echoed_extensions) }
      end
      validator_issues_to_messages(issues)
    end

    # Same as collect_resource_profile_messages for a Bundle, additionally dropping
    # entry-resource-level issues that are covered by individual resource validation
    # to avoid duplicate messages.
    # @param bundle [FHIR::Bundle] The Bundle resource to validate.
    # @param profile_url [String] The profile URL (with version) to validate against.
    # @return [Array<Hash>] Message hashes for the Bundle-structural issues found.
    def collect_bundle_profile_messages(bundle, profile_url)
      response_details = []
      resource_is_valid?(resource: bundle, profile_url:, validator: profile_validator,
                         add_messages_to_runnable: false,
                         validator_response_details: response_details)
      validator_issues_to_messages(reject_entry_resource_issues(response_details))
    end

    def validator_issues_to_messages(issues)
      issues.map { |issue| { type: issue.severity, message: issue.message } }
    end

    # Rejects validator issues that are already filtered or are located at/below
    # Bundle.entry[N].resource, since those are validated individually per resource.
    # @param issues [Array<ValidatorIssue>] Raw issues from the validator.
    # @return [Array<ValidatorIssue>] Issues relevant only to the Bundle structure itself.
    #
    # Entry resources that receive direct PAS or US Core target profiles are validated individually after this filter.
    def reject_entry_resource_issues(issues)
      issues.reject do |issue|
        issue.filtered || issue.location&.match?(/\ABundle\.entry\[\d+\]\.resource/)
      end
    end

    def generate_non_conformance_message(item)
      "#{item[:resource].resourceType}/#{item[:resource].id} is not conformant to any of the " \
        "target profiles: #{item[:profile_urls]}."
    end

    # Processes each entry in a FHIR bundle to extract resource and possible profiles to validate against.
    # It recursively evaluates referenced instances and their profiles, expanding the validation scope.
    # @param bundle_entry [Object] The current bundle entry being processed.
    # @param current_entry [Object] The current entry within the bundle.
    # @param current_entry_profile_url [String] The profile URL associated with the current entry.
    # @param version [String] The IG version.
    def extract_profiles_to_validate_each_entry(bundle_entry, current_entry, current_entry_profile_url, version)
      return if current_entry.blank?

      # NOTE: the IG does not have the metadata for us-core profiles.
      metadata = metadata_map("v#{version}")[profile_url_without_version(current_entry_profile_url)]
      return if metadata.blank?

      bundle_map = bundle_entry_map(bundle_entry)
      reference_elements = metadata.references.dup

      # Special handling for Claim submit profile
      claim_submit_profile_urls = [
        PASConstants::CLAIM_PROFILE,
        PASConstants::CLAIM_PROFILE_FIRST_SUBMIT
      ]
      if claim_submit_profile_urls.include?(current_entry_profile_url)
        handle_claim_profile(reference_elements,
                             current_entry_profile_url)
      end

      reference_elements.each do |reference_element|
        process_reference_element(reference_element, current_entry, bundle_entry, bundle_map, version)
      end
    end

    # Handles the special case for the Claim profile in a FHIR bundle.
    # It adds missing reference elements for the Claim profile.
    # Claim.item.extension:requestedService value is a reference, but somehow not included in the metadata references.
    # @param reference_elements [Array] The array of reference elements to be updated.
    # @param current_entry_profile_url [String] The profile URL of the current entry being processed.
    def handle_claim_profile(reference_elements, current_entry_profile_url)
      claim_submit_profile_urls = [
        PASConstants::CLAIM_PROFILE,
        PASConstants::CLAIM_PROFILE_FIRST_SUBMIT
      ]
      return unless claim_submit_profile_urls.include?(current_entry_profile_url)

      claim_ref_element = {
        path: 'Claim.item.extension.value',
        profiles: [
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-medicationrequest',
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-servicerequest',
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-devicerequest',
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-nutritionorder'
        ]
      }

      # This temporary traversal handling may be replaced later by shared metadata-driven navigation logic.
      claim_encounter_ref_element = {
        path: "Claim.extension.where(url = '#{CLAIM_ENCOUNTER_EXTENSION_URL}').value",
        profiles: [
          'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-encounter'
        ]
      }

      reference_elements << claim_ref_element
      reference_elements << claim_encounter_ref_element
    end

    # Processes a given reference element definition from a FHIR bundle entry.
    # It evaluates FHIRPath expressions and processes each referenced instance and its profiles.
    # @param reference_element [Hash] The reference element to process.
    # @param current_entry [Object] The current entry within the FHIR bundle.
    # @param bundle_entry [Array] The bundle.entry.
    # @param bundle_map [Hash] A map of the bundle contents.
    # @param version [String] The FHIR version.
    def process_reference_element(reference_element, current_entry, bundle_entry, bundle_map, version)
      fhirpath_result = evaluate_fhirpath(resource: current_entry.resource, path: reference_element[:path])
      reference_element_values = fhirpath_result.filter_map do |entry|
        entry['element']&.reference if entry['type'] == 'Reference'
      end

      referenced_instances = reference_element_values.filter_map do |value|
        find_referenced_instance_in_bundle(value, current_entry.fullUrl, bundle_map)
      end

      referenced_instances.each do |instance|
        process_instance_profiles(instance, bundle_entry, reference_element, version)
      end
    end

    # Processes the profiles associated with a given instance in a FHIR bundle.
    # It adds the instance's profiles to the resource target profile map and handles recursive profile extraction.
    # The profiles collected here are possible profiles the given instance may conform to.
    # The conformance validation will ensure that the resource is conformant to at least one of the target profiles.
    # @param instance [Object] The instance whose profiles are to be processed.
    # @param bundle_entry [Array] The bundle.entry contents.
    # @param reference_element [Hash] The reference element related to the instance.
    # @param version [String] The IG version.
    def process_instance_profiles(instance, bundle_entry, reference_element, version)
      add_resource_target_profile_to_map(instance.fullUrl, instance.resource)
      # Add the declared profile conformance
      add_declared_profiles(instance, bundle_entry, version)

      reference_element[:profiles].each do |profile_url|
        # NOTE: the IG does not have the metadata for us-core profiles.
        target_metadata = metadata_map("v#{version}")[profile_url_without_version(profile_url)]
        resource_type = instance.resource.resourceType
        next unless target_metadata&.resource == resource_type || profile_url.include?(resource_type)

        add_profile_to_instance(instance, profile_url, bundle_entry, version)
        # NOTE: The algorithm assumes OR semantics for profile conformance, where the resource needs to conform to
        # at least one of the collected profiles. However, it may not cover all scenarios, such as cases
        # where AND semantics are required for multiple profile conformance. Also, it does not address complex
        # situations where profile requirements may conflict or have dependencies across referenced instances.
        # Therefore, this algorithm may not provide complete validation for all scenarios, and additional checks may be
        # necessary depending on the use case.
      end
    end

    # Adds declared profiles from an instance (meta.profile) to the resource target profile map.
    # It recursively processes each entry for further profile extraction.
    # @param instance [Object] The instance from which profiles are extracted.
    # @param bundle_entry [Array] The bundle.entry contents.
    # @param version [String] The IG version.
    def add_declared_profiles(instance, bundle_entry, version)
      return unless instance.resource.present?

      instance.resource.meta&.profile&.each do |url|
        next if bundle_resources_target_profile_map[instance.fullUrl][:profile_urls].include?(url)

        bundle_resources_target_profile_map[instance.fullUrl][:profile_urls] << url
        extract_profiles_to_validate_each_entry(bundle_entry, instance, url, version)
      end
    end

    # Adds a specific profile URL to an instance in the resource target profile map.
    # It recursively processes the instance for further profile extraction.
    # @param instance [Object] The instance to which the profile URL is added.
    # @param profile_url [String] The profile URL to be added.
    # @param bundle_entry [Array] The bundle.entry contents.
    # @param version [String] The IG version.
    def add_profile_to_instance(instance, profile_url, bundle_entry, version)
      return if bundle_resources_target_profile_map[instance.fullUrl][:profile_urls].include?(profile_url)

      bundle_resources_target_profile_map[instance.fullUrl][:profile_urls] << profile_url
      extract_profiles_to_validate_each_entry(bundle_entry, instance, profile_url, version)
    end

    # Mapping profile url to metadata
    def metadata_map(version)
      @metadata ||= {}
      @metadata[version] ||= YAML.load_file(File.join(__dir__, "generated/#{version}/metadata.yml"),
                                            aliases: true)
      @metadata_map ||= {}
      @metadata_map[version] ||= @metadata[version][:profiles].to_h do |profile_metadata|
        [profile_metadata[:profile_url], Generator::ProfileMetadata.new(profile_metadata)]
      end
    end

    def bundle_entry_map(bundle_entry)
      @bundle_entry_map ||= bundle_entry.to_h do |entry|
        [entry.fullUrl, entry]
      end
    end

    # Finds a referenced instance in a FHIR bundle based on a reference and the full URL of the enclosing entry.
    # @param reference [String] The reference to find.
    # @param enclosing_entry_fullurl [String] The full URL of the enclosing entry.
    # @param bundle_map [Hash] A map of the bundle contents.
    # @return [Object] The found instance, or nil if not found.
    def find_referenced_instance_in_bundle(reference, enclosing_entry_fullurl, bundle_map)
      base_url = extract_base_url(enclosing_entry_fullurl)
      key = absolute_url(reference, base_url)

      bundle_map[key]
    end

    # Resource Types to validate in request/ response bundle
    def find_profile_url(request_type)
      {
        'Claim' => if request_type.start_with?('submit')
                     PASConstants::CLAIM_PROFILE
                   else
                     PASConstants::CLAIM_INQUIRY_PROFILE
                   end,
        'ClaimResponse' => if %w[submit submit_response].include?(request_type)
                             PASConstants::CLAIM_RESPONSE_PROFILE
                           else
                             PASConstants::CLAIM_INQUIRY_RESPONSE_PROFILE
                           end
      }
    end

    # Determines the target profile URL for a Claim resource in a submit request bundle.
    #
    # In PAS v2.2.1, profile-pas-request-bundle permits either profile-claim or profile-claim-update.
    # The structural discriminator is Claim.related: profile-claim-update requires it (must-support)
    # while profile-claim disallows it (max: 0). For all other versions, profile-claim-update is
    # used unconditionally.
    #
    # @param version [String] The IG version (e.g. '2.2.1').
    # @param claim [FHIR::Claim] The Claim resource to inspect.
    # @return [String] The profile URL to validate against.
    def determine_claim_submit_profile_url(version, claim)
      return PASConstants::CLAIM_PROFILE unless version == '2.2.1'

      if claim.related.blank?
        PASConstants::CLAIM_PROFILE_FIRST_SUBMIT
      else
        PASConstants::CLAIM_PROFILE
      end
    end

    # Checks the following requirement:
    # The Claim.supportingInfo.sequence for each entry SHALL be unique within the Claim.
    #
    # @param claim [FHIR::Claim] The FHIR Claim resource.
    # Since the cardinality for Claim.supportingInfo is 0..*,
    # we will check the uniqueness if Array not empty.
    def validate_uniqueness_of_supporting_info_sequences(claim)
      return unless claim.is_a?(FHIR::Claim)

      supporting_info = claim.supportingInfo
      return unless supporting_info.present?

      sequences = supporting_info.map(&:sequence)
      is_unique = sequences.uniq.length == sequences.length
      return if is_unique

      add_validation_error("[Claim/#{claim.id}]: The sequence element for each supportingInfo entry SHALL be " \
                           'unique within the Claim.')
    end

    def validate_bundle_entries_full_url(bundle)
      msg = "[Bundle/#{bundle.id}]: Bundle.entry.fullUrl values SHALL be a valid url or in the form " \
            "'urn:uuid:[some guid]'."
      bundle.entry.each do |entry|
        add_validation_error(msg) unless valid_url_or_urn_uuid?(entry.fullUrl)
      end
    end

    # Checks if a string is a valid url or in the form “urn:uuid:[some guid]”
    # @param string [String] The url string to check
    # @return true if valid url or urn_uuid, otherwise false
    def valid_url_or_urn_uuid?(string)
      url_regex = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
      urn_uuid_regex = /\Aurn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

      string&.match?(url_regex) || string&.match?(urn_uuid_regex)
    end

    # Generates a message for a resource present in both the PA request and response bundles.
    #
    # @param resource [FHIR::Model] The resource present in both bundles.
    #
    # This method generates an error message when a resource appears in both the PA request
    # and response bundles but does not have the same fullUrl or identifiers.
    def resource_present_in_pa_request_and_response_msg(resource)
      "Resource #{resource.resourceType}/#{resource.id} is an entry in both the PA Request Bundle and the Response " \
        'Bundle, but they do not have the same fullUrl or identifiers'
    end

    ###########################################################################
    # US Core Version Constants
    ###########################################################################

    US_CORE_VERSION = '6.1.0'
    US_CORE_PROFILE_BASE = 'http://hl7.org/fhir/us/core/StructureDefinition'
    BASE_R4_PROFILE = :base_r4
    CLAIM_ENCOUNTER_EXTENSION_URL = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-Claim.encounter'
    LOINC_SYSTEM = 'http://loinc.org'
    TERMINOLOGY_CONDITION_CATEGORY_SYSTEM = 'http://terminology.hl7.org/CodeSystem/condition-category'
    OBSERVATION_CATEGORY_SYSTEM = 'http://terminology.hl7.org/CodeSystem/observation-category'
    DIAGNOSTIC_REPORT_CATEGORY_SYSTEM = 'http://terminology.hl7.org/CodeSystem/v2-0074'

    US_CORE_SINGLE_PROFILE_IDS_BY_RESOURCE = {
      'AllergyIntolerance' => 'us-core-allergyintolerance',
      'CarePlan' => 'us-core-careplan',
      'CareTeam' => 'us-core-careteam',
      'Coverage' => 'us-core-coverage',
      'Device' => 'us-core-implantable-device',
      'DocumentReference' => 'us-core-documentreference',
      'Encounter' => 'us-core-encounter',
      'Goal' => 'us-core-goal',
      'Immunization' => 'us-core-immunization',
      'Location' => 'us-core-location',
      'Medication' => 'us-core-medication',
      'MedicationDispense' => 'us-core-medicationdispense',
      'MedicationRequest' => 'us-core-medicationrequest',
      'Organization' => 'us-core-organization',
      'Patient' => 'us-core-patient',
      'Practitioner' => 'us-core-practitioner',
      'PractitionerRole' => 'us-core-practitionerrole',
      'Procedure' => 'us-core-procedure',
      'Provenance' => 'us-core-provenance',
      'QuestionnaireResponse' => 'us-core-questionnaireresponse',
      'RelatedPerson' => 'us-core-relatedperson',
      'ServiceRequest' => 'us-core-servicerequest',
      'Specimen' => 'us-core-specimen'
    }.freeze

    US_CORE_CONDITION_ENCOUNTER_DIAGNOSIS_PROFILE_ID = 'us-core-condition-encounter-diagnosis'
    US_CORE_CONDITION_PROBLEMS_HEALTH_CONCERNS_PROFILE_ID = 'us-core-condition-problems-health-concerns'
    US_CORE_DIAGNOSTIC_REPORT_LAB_PROFILE_ID = 'us-core-diagnosticreport-lab'
    US_CORE_DIAGNOSTIC_REPORT_NOTE_PROFILE_ID = 'us-core-diagnosticreport-note'
    US_CORE_OBSERVATION_CLINICAL_RESULT_PROFILE_ID = 'us-core-observation-clinical-result'
    US_CORE_OBSERVATION_LAB_PROFILE_ID = 'us-core-observation-lab'
    US_CORE_OBSERVATION_SCREENING_ASSESSMENT_PROFILE_ID = 'us-core-observation-screening-assessment'
    US_CORE_SIMPLE_OBSERVATION_PROFILE_ID = 'us-core-simple-observation'
    US_CORE_SMOKING_STATUS_PROFILE_ID = 'us-core-smokingstatus'
    US_CORE_VITAL_SIGNS_PROFILE_ID = 'us-core-vital-signs'

    US_CORE_OBSERVATION_CODE_PROFILE_IDS = {
      '11341-5' => 'us-core-observation-occupation',
      '86645-9' => 'us-core-observation-pregnancyintent',
      '82810-3' => 'us-core-observation-pregnancystatus',
      '76690-7' => 'us-core-observation-sexual-orientation',
      '8289-1' => 'head-occipital-frontal-circumference-percentile',
      '59576-9' => 'pediatric-bmi-for-age',
      '77606-2' => 'pediatric-weight-for-height',
      '85354-9' => 'us-core-blood-pressure',
      '39156-5' => 'us-core-bmi',
      '8302-2' => 'us-core-body-height',
      '8310-5' => 'us-core-body-temperature',
      '29463-7' => 'us-core-body-weight',
      '9843-4' => 'us-core-head-circumference',
      '8867-4' => 'us-core-heart-rate',
      '59408-5' => 'us-core-pulse-oximetry',
      '2708-6' => 'us-core-pulse-oximetry',
      '9279-1' => 'us-core-respiratory-rate',
      '72166-2' => 'us-core-smokingstatus'
    }.freeze
  end
end
