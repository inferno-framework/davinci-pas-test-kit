# frozen_string_literal: true

require_relative '../parameters_helper'
require_relative 'validation_test'
require_relative 'pas_constants'

module DaVinciPASTestKit
  module PasBundleValidation
    include DaVinciPASTestKit::ValidationTest
    include ParametersHelper

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

    def validation_error_messages
      @validation_error_messages ||= []
    end

    def perform_bundle_validation(bundle, operation, type, ig_version)
      target_profile = PASConstants.bundle_profile_url_for_operation_and_type(operation, type)
      request_type = "#{operation}_#{type}"
      if type == 'request'
        perform_request_validation(bundle, target_profile, ig_version.delete_prefix('v'), request_type)
      else
        perform_response_validation(bundle, target_profile, ig_version.delete_prefix('v'), request_type)
      end
    end

    def perform_request_validation(bundle, profile_url, version, request_type)
      validate_pa_request_payload_structure(bundle, request_type)
      validate_resources_conformance_against_profile(bundle, profile_url, version, request_type)
    end

    def perform_response_validation(response_bundle, profile_url, version, request_type, request_bundle = nil)
      validate_pa_response_body_structure(response_bundle, request_bundle) if request_type == 'submit'
      validate_resources_conformance_against_profile(response_bundle, profile_url, version, request_type)
    end

    def validate_pas_bundle_json(json, profile_url, version, request_type, bundle_type, skips: false, message: '')
      assert_valid_json(json)
      resource = FHIR.from_contents(json)
      assert resource.present?, 'Not a FHIR resource'

      # For v2.2.0 inquire responses, expect Parameters resource
      if version == '2.2.0' && request_type == 'inquire' && bundle_type == 'response_bundle'
        if resource.resourceType == 'Parameters'
          # Extract and validate each Bundle in the Parameters
          bundles = extract_bundles_from_pas_inquiry_response_parameters(resource)

          bundles.each do |bundle|
            perform_response_validation(bundle, profile_url, version, request_type)
          end
        elsif resource.is_a?(FHIR::Bundle)
          # Bundle received instead of Parameters - validate it but log an error
          validation_error_messages << 'Expected Parameters resource for v2.2.0 inquire response, but received ' \
                                       'Bundle. The response Bundle should be wrapped in a ' \
                                       'Parameters resource with a return parameter.'
          perform_response_validation(resource, profile_url, version, request_type)
        else
          assert false,
                 "Expected Parameters resource for v2.2.0 inquire response, but received #{resource.resourceType}"
        end
      else
        # For v2.0.1 or non-inquire operations, expect Bundle resource
        assert_resource_type(:bundle, resource: resource)
        bundle = resource

        if bundle_type == 'request_bundle'
          perform_request_validation(bundle, profile_url, version, request_type)
        else
          perform_response_validation(bundle, profile_url, version, request_type)
        end
      end

      validation_error_messages.each do |msg|
        messages << { type: 'error', message: msg }
      end
      msg = 'Bundle response returned and/or entry resources are not conformant. Check messages for issues found.'
      assert validation_error_messages.blank?, msg
    rescue Inferno::Exceptions::AssertionException => e
      msg = "#{message} #{e.message}".strip
      raise e.class, msg unless skips

      skip msg
    end

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

      if request_type == 'submit'
        unless first_entry.is_a?(FHIR::Claim)
          validation_error_messages << "[Bundle/#{bundle.id}]: The first bundle entry must be a Claim"
        end

        validate_uniqueness_of_supporting_info_sequences(first_entry)
        validate_bundle_entries_full_url(bundle)
      else
        claim_resource = bundle_entry_resources.find { |resource| resource.resourceType == 'Claim' }
        if claim_resource.blank?
          validation_error_messages << "[Bundle/#{bundle.id}]: Claim must be present for inquiry request"
        end

        # The inquiry operation must contain a requesting provider organization,
        # a payer organization, and a patient for the inquiry
        patient_reference = claim_resource&.patient&.reference
        provider_reference = claim_resource&.provider&.reference
        payer_reference = claim_resource&.insurer&.reference

        if patient_reference.blank?
          validation_error_messages <<
            "[Bundle/#{bundle.id}]: The Claim for inquiry operation must reference a patient."
        end
        if provider_reference.blank?
          validation_error_messages << "[Bundle/#{bundle.id}]: The claim for inquiry operation must reference " \
                                       'a requesting provider organization.'
        end
        if payer_reference.blank?
          validation_error_messages << "[Bundle/#{bundle.id}]: The Claim for inquiry operation must contain " \
                                       'a payer organization.'
        end
      end
    end

    # Validates the response body structure of a Prior Authorization (PA) response.
    #
    # @param pa_response_bundle [FHIR::Bundle] The FHIR bundle representing the PA response.
    # @param pa_request_bundle [String] The JSON payload of the PA request bundle.
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
    def validate_pa_response_body_structure(pa_response_bundle, _pa_request_bundle)
      first_entry = pa_response_bundle.entry.first.resource
      unless first_entry.is_a?(FHIR::ClaimResponse)
        validation_error_messages <<
          "[Bundle/#{pa_response_bundle.id}]: The first bundle entry must be a ClaimResponse"
      end

      base_url = extract_base_url(pa_response_bundle.entry.last&.fullUrl)
      check_presence_of_referenced_resources(first_entry, base_url, pa_response_bundle.entry)

      # Testing: When echoing back resources that are the same as were present in the prior authorization request,
      # the system SHALL ensure that the same fullUrl and resource identifiers are used in the response as appeared
      # in the request
      # pa_request_bundle = FHIR.from_contents(pa_request_bundle)
      # pa_response_bundle.entry.each do |entry|
      #   res = entry.resource
      #   request_entry = pa_request_bundle.entry.find do |ent|
      #     ent.resource.resourceType == res.resourceType && ent.resource.id == res.id
      #   end
      #   next unless request_entry.present?

      #   assert(
      #     request_entry.fullUrl == entry.fullUrl && request_entry.resource.identifier == res.identifier,
      #     resource_present_in_pa_request_and_response_msg(res)
      #   )
      # end
    end

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
        ['Claim', 'ClaimResponse'].include?(entry.resource.resourceType)
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
    # It logs a message for each conformant entry
    # and collects error messages for non-conformant entries. Asserts that there are no validation errors.
    # @param version [String] The version of the IG.
    def validate_bundle_entries_against_profiles(version)
      bundle_resources_target_profile_map.each do |key, item|
        resource = item[:resource]
        base_profile = FHIR::Definitions.resource_definition(resource.resourceType).url

        success_profile = item[:profile_urls].find do |url|
          if key == 'bundle'
            profile_to_validate = profile_url_for_validation(url, base_profile, version)
            bundle_profile_valid?(resource, profile_to_validate)
          elsif url == BASE_R4_PROFILE
            resource_is_valid?(resource:)
          else
            profile_to_validate = profile_url_for_validation(url, base_profile, version)
            resource_is_valid?(resource:, profile_url: profile_to_validate)
          end
        end

        validation_error_messages << generate_non_conformance_message(item) unless success_profile
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

    # Validates a Bundle resource against a profile, filtering out entry-resource-level issues
    # that are covered by individual resource validation to avoid duplicate messages.
    # @param bundle [FHIR::Bundle] The Bundle resource to validate.
    # @param profile_url [String] The profile URL (with version) to validate against.
    # @return [Boolean] true if no unfiltered errors remain after removing entry-resource issues.
    def bundle_profile_valid?(bundle, profile_url)
      response_details = []
      resource_is_valid?(resource: bundle, profile_url:,
                         add_messages_to_runnable: false,
                         validator_response_details: response_details)
      bundle_level_issues = reject_entry_resource_issues(response_details)
      bundle_level_issues.each { |issue| messages << { type: issue.severity, message: issue.message } }
      bundle_level_issues.none? { |issue| issue.severity == 'error' }
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
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim'
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
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim'
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
      @metadata_map[version] ||= @metadata[version][:profiles].each_with_object({}) do |profile_metadata, obj|
        obj[profile_metadata[:profile_url]] = Generator::ProfileMetadata.new(profile_metadata)
      end
    end

    def bundle_entry_map(bundle_entry)
      @bundle_entry_map ||= bundle_entry.each_with_object({}) do |entry, obj|
        obj[entry.fullUrl] = entry
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

    def absolute_url(reference, base_url)
      return if reference.blank?
      return reference if base_url.blank? || reference.starts_with?('urn:uuid:') || URI(reference).absolute?

      "#{base_url}/#{reference}"
    end

    # Extracts the base URL from an absolute URL by removing the resource type and ID.
    # @param absolute_url [String] The absolute URL.
    # @return [String] The base URL, or an empty string if the URL format is not as expected.
    def extract_base_url(absolute_url)
      return '' if absolute_url.blank?

      uri = URI(absolute_url)
      return '' unless uri.scheme && uri.host

      # Split the path segments and remove the last two segments (resource type and id)
      path_segments = uri.path.split('/')
      base_path = path_segments[0...-2].join('/')

      "#{uri.scheme}://#{uri.host}#{base_path}"
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
    # In v2.2.0, profile-pas-request-bundle permits either profile-claim or profile-claim-update.
    # The structural discriminator is Claim.related: profile-claim-update requires it (must-support)
    # while profile-claim disallows it (max: 0). For all other versions, profile-claim-update is
    # used unconditionally.
    #
    # @param version [String] The IG version (e.g. '2.2.0').
    # @param claim [FHIR::Claim] The Claim resource to inspect.
    # @return [String] The profile URL to validate against.
    def determine_claim_submit_profile_url(version, claim)
      return PASConstants::CLAIM_PROFILE unless version == '2.2.0'

      if claim.related.blank?
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claim'
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

      validation_error_messages << "[Claim/#{claim.id}]: The sequence element for each supportingInfo entry SHALL be " \
                                   'unique within the Claim.'
    end

    def validate_bundle_entries_full_url(bundle)
      msg = "[Bundle/#{bundle.id}]: Bundle.entry.fullUrl values SHALL be a valid url or in the form " \
            "'urn:uuid:[some guid]'."
      bundle.entry.each do |entry|
        validation_error_messages << msg unless valid_url_or_urn_uuid?(entry.fullUrl)
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

    # This method traverses references within a FHIR resource, ensuring that referenced resources
    # are populated in the bundle. It also enforces that a referenced resource appears only once in the bundle,
    # as required by the PAS IG.
    # @param target_resource [FHIR::Model] The FHIR resource to traverse and validate.
    # @param base_url [String] The server base url.
    # @param resources_to_match [Array<FHIR:Bundle:Entry] The list of FHIR bundle entries to match references against.
    def check_presence_of_referenced_resources(target_resource, base_url, resources_to_match)
      return if target_resource.blank?

      if target_resource.is_a?(FHIR::Reference) && target_resource.reference.present?
        ref = target_resource.reference
        return if ref.blank?

        absolute_ref = absolute_url(ref, base_url)
        matching_resources = resources_to_match.find_all { |res| res.fullUrl == absolute_ref }

        if matching_resources.length != 1
          validation_error_messages << resource_shall_appear_once_message(absolute_ref,
                                                                          matching_resources.length)
        end

        if matching_resources.length.positive?
          check_presence_of_referenced_resources(matching_resources.first, base_url, resources_to_match)
        end
      else
        target_resource.source_hash.each_key do |attr|
          next if claim_response_request_attr?(target_resource, attr)

          value = target_resource.send(attr.to_sym)
          if value.is_a?(FHIR::Model)
            check_presence_of_referenced_resources(value, base_url, resources_to_match)
          elsif value.is_a?(Array) && value.all? { |elmt| elmt.is_a?(FHIR::Model) }
            value.each { |elmt| check_presence_of_referenced_resources(elmt, base_url, resources_to_match) }
          end
        end
      end
    end

    # ClaimResponse.request is a back-reference to the submitted Claim. The PAS IG response bundle
    # profile (profile-pas-response-bundle) has no required Claim entry slice, so the Claim need
    # not be present in the response bundle. Skipping here matches the identical guard in
    # ResponseGenerator#referenced_entities, which also skips ClaimResponse.request when
    # building mock response bundles.
    def claim_response_request_attr?(resource, attr)
      attr.to_s == 'request' &&
        resource.respond_to?(:resourceType) &&
        resource.resourceType == 'ClaimResponse'
    end

    # Extracts resources from a bundle while following "next" links.
    #
    # @param bundle [FHIR::Bundle] The initial FHIR bundle to extract resources from.
    # @param response [Object] The HTTP response object for the bundle retrieval.
    # @param reply_handler [Proc] A callback function to handle responses.
    # @param max_pages [Integer] The maximum number of pages to process.
    #
    # This method extracts resources from a FHIR bundle, following "next" links in the bundle
    # until the specified maximum number of pages is reached. It collects resources and
    # invokes the reply_handler for each response.
    def extract_resources_from_bundle(
      bundle: nil,
      response: nil,
      reply_handler: nil,
      max_pages: 20
    )
      page_count = 1
      resources = []

      until bundle.nil? || page_count == max_pages
        resources += bundle&.entry&.map { |entry| entry&.resource }
        next_bundle_link = bundle&.link&.find { |link| link.relation == 'next' }&.url
        reply_handler&.call(response)

        break if next_bundle_link.blank?

        page_count += 1
      end

      resources
    end

    # Generates a message for a resource that appears more than once in a bundle.
    #
    # @param reference_resource_type [String] The resource type being referenced.
    # @param reference_resource_id [String] The resource ID being referenced.
    # @param total_matches [Integer] The total number of matches found in the bundle.
    #
    # This method generates an error message when a referenced resource appears more than once
    # in a FHIR bundle, which is not allowed.
    def resource_shall_appear_once_message(absolute_ref, total_matches)
      " The referenced #{absolute_ref} resource SHALL appear exactly once in the Bundle, but found #{total_matches}."
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
  end
end
