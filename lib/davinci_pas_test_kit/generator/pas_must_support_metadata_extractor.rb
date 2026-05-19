require 'inferno/dsl/must_support_metadata_extractor'

module DaVinciPASTestKit
  # The MustSupportMetadataExtractor takes a StructureDefinition and parses it into a hash-based metadata
  #  that simplifies checking for MustSupport elements.
  # MustSupport elements may be either plain elements, extensions, or slices.
  # This logic was originally developed for the US Core Test Kit and has been migrated into Inferno core.
  class PASMustSupportMetadataExtractor < Inferno::DSL::MustSupportMetadataExtractor
    # Override save_pattern_slice to handle patternIdentifier slices that discriminate on
    # identifier.type.coding (e.g. Organization.identifier:PI) rather than identifier.system.
    # inferno_core only extracts .system from patternIdentifier, leaving it nil for type-coded
    # slices, which causes find_pattern_identifier_slice to never match at runtime.
    # When patternIdentifier.type.coding is present, emit a patternCodeableConcept discriminator
    # on path 'type' instead, which inferno_core CAN navigate at runtime.
    def save_pattern_slice(pattern_element, discriminator_path, metadata)
      pi_type = pattern_element.patternIdentifier&.type
      coding = pi_type&.coding&.first
      if coding
        runtime_path = navigation_compatible_discriminator_path(discriminator_path)
        path = runtime_path.present? ? "#{runtime_path}.type" : 'type'
        return {
          type: 'patternCodeableConcept',
          path: path,
          code: coding.code,
          system: coding.system
        }
      end
      super
    end

    def must_support_slice_elements
      all_must_support_elements.select do |element|
        !element.path.end_with?('xtension') && element.sliceName.present?
      end
    end

    def must_support_extension_elements
      all_must_support_elements.select { |element| element.path.end_with? 'xtension' }
    end

    def must_support_extensions
      must_support_extension_elements.map do |element|
        {
          id: element.id,
          path: element.path.gsub("#{resource}.", ''),
          url: element.type.first.profile.first,
          modifier_extension: element.path.end_with?('modifierExtension')
        }.tap do |metadata|
          metadata[:by_requirement_extension_only] = true if by_requirement_extension_only?(element)
        end
      end
    end

    def find_element_by_discriminator_path(current_element, discriminator_path)
      target_element = current_element
      remaining_path = discriminator_path

      while remaining_path.present?
        target_element, remaining_path = take_discriminator_step(target_element, remaining_path)
      end

      target_element
    end

    def take_discriminator_step(current_element, path)
      if path.start_with?('extension(')
        ext_url, remaining_path = path.delete_prefix("extension('").split("')", 2)
        next_element = profile_elements.find do |element|
          element.path == "#{current_element.path}.extension" &&
            element.id.start_with?("#{current_element.id}.extension:") &&
            element.type.any? { |type| type.code == 'Extension' && type.profile.any? { |p| p.start_with?(ext_url) } }
        end
      else
        step_path, remaining_path = path.split('.', 2)
        if remaining_path&.start_with?('ofType(')
          target_element = "#{step_path}[x]"
          target_type, remaining_path = remaining_path.delete_prefix('ofType(').split(')', 2)
          next_element = profile_elements.find do |element|
            element.id == "#{current_element.id}.#{target_element}" &&
              element.type.any? { |type| type.code == target_type }
          end
        else
          next_element =
            profile_elements.find { |element| element.id == "#{current_element.id}.#{step_path}" } ||
            profile_elements.find { |element| element.id == "#{current_element.path}.#{step_path}" }
        end
      end

      [next_element, remaining_path&.delete_prefix('.')]
    end

    # Returns non-must-support slice elements that have at least one must-support descendant.
    # These slices are recorded in the metadata as :optional_slices so that the runtime test can:
    #   1. Temporarily merge them into :slices for navigation (inferno_core's
    #      find_slice_via_discriminator looks up slices by name from :slices).
    #   2. Conditionally skip must-support failures for elements under an optional slice when
    #      that slice is absent from all collected resources (it was never sent → can't validate
    #      children). If the slice IS present in some resource, children are still checked.
    #
    # Example: In PAS v2.0.1, Claim.supportingInfo:PatientEvent is not MS but its child
    # timing[x] is. PatientEvent is added to :optional_slices. At runtime, if PatientEvent is
    # sent, timing[x] is validated; if PatientEvent is never sent, the timing[x] check is skipped.
    # In v2.2.0, PatientEvent is MS so it appears in the regular :slices instead.
    #
    # The same pattern applies to type-choice slices: v2.2.0 adds timing[x]:timingPeriod.start
    # as MS, but timingPeriod (a type-slice of timing[x]) is not itself MS, so it ends up here.
    def optional_slices
      ms_slice_names = must_support_slices.map { |s| s[:slice_name] }.compact.to_set

      candidate_slices = profile_elements.reject do |e|
        e.sliceName.blank? ||
          e.path.end_with?('extension') ||
          ms_slice_names.include?(e.sliceName)
      end
      non_ms_with_ms_children = candidate_slices.select do |e|
        all_must_support_elements.any? { |ms_el| ms_el.id.start_with?("#{e.id}.") }
      end

      non_ms_with_ms_children.filter_map do |current_element|
        sliced = sliced_element(current_element)
        next if sliced.nil?

        element_discriminators = discriminators(sliced)

        metadata = {
          slice_id: current_element.id,
          slice_name: current_element.sliceName,
          path: current_element.path.gsub("#{resource}.", ''),
          optional: true
        }

        build_optional_slice_discriminator(current_element, element_discriminators, metadata)
      end
    end

    def build_optional_slice_discriminator(current_element, element_discriminators, metadata)
      if element_discriminators.blank?
        return unless current_element.type&.one?

        type_code = current_element.type.first&.code
        return unless type_code

        metadata[:discriminator] = { type: 'type', code: type_code.upcase_first }
      elsif element_discriminators.first.type == 'type'
        type_path = discriminator_path(element_discriminators.first)
        type_element = find_element_by_discriminator_path(current_element, type_path)
        return unless type_element

        type_code = type_element.type&.first&.code
        return unless type_code

        metadata[:discriminator] = { type: 'type', code: type_code.upcase_first }
      else
        add_optional_slice_value_discriminator(element_discriminators, current_element, metadata)
        return unless metadata[:discriminator].present?
      end

      metadata
    end

    def add_optional_slice_value_discriminator(element_discriminators, current_element, metadata)
      fixed_values = []
      pattern_value = {}

      element_discriminators.each do |discriminator|
        disc_path = discriminator_path(discriminator)
        pattern_element = find_element_by_discriminator_path(current_element, disc_path)

        next if pattern_element.nil? && element_discriminators.length > 1
        next if pattern_element.nil?

        if !pattern_element.fixed.nil?
          fixed_values << { path: navigation_compatible_discriminator_path(disc_path),
                            value: pattern_element.fixed }
        elsif pattern_value.present?
          next
        else
          pattern_value = save_pattern_slice(pattern_element, disc_path, metadata)
        end
      end

      if fixed_values.present?
        metadata[:discriminator] = { type: 'value', values: fixed_values }
      elsif pattern_value.present?
        metadata[:discriminator] = pattern_value
      end
    end

    # Adds :optional_slices to the standard must_supports hash so the generated YAML carries
    # navigation discriminator info for non-MS parent slices. inferno_core ignores this key;
    # PAS's MustSupportDataGathering reads it at runtime.
    def must_supports
      base = super
      opt = optional_slices
      return base if opt.empty?

      base.merge(optional_slices: opt)
    end

    def value_slices
      must_support_value_slice_elements.map do |current_element|
        {
          slice_id: current_element.id,
          slice_name: current_element.sliceName,
          path: current_element.path.gsub("#{resource}.", '')
        }.tap do |metadata|
          fixed_values = []
          pattern_value = {}

          element_discriminators = discriminators(sliced_element(current_element))

          element_discriminators.each do |discriminator|
            discriminator_path = discriminator_path(discriminator)
            pattern_element = find_element_by_discriminator_path(current_element, discriminator_path)

            # This is a workaround for a known version of a profile that has a bad discriminator:
            # the discriminator refers to a nested field within a CodeableConcept,
            # but the profile doesn't contain an element definition for it, so there's no way to
            # define a fixed value on the element to define the slice.
            # In this instance the element has a second (good) discriminator on the CodeableConcept field itself,
            # and in subsequent versions of the profile, the bad discriminator was removed.
            next if pattern_element.nil? && element_discriminators.length > 1

            if !pattern_element.fixed.nil?
              fixed_values << {
                path: navigation_compatible_discriminator_path(discriminator_path),
                value: pattern_element.fixed
              }
            elsif pattern_value.present?
              raise StandardError, "Found more than one pattern slices for the same element #{pattern_element}."
            else
              pattern_value = save_pattern_slice(pattern_element, discriminator_path, metadata)
            end
          end

          if fixed_values.present?
            metadata[:discriminator] = {
              type: 'value',
              values: fixed_values
            }
          elsif pattern_value.present?
            metadata[:discriminator] = pattern_value
          end

          metadata[:by_requirement_extension_only] = true if by_requirement_extension_only?(current_element)
        end
      end
    end
  end
end
