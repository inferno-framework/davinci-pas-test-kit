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

    def find_element_by_discriminator_path(current_element, discriminator_path)
      target_element = current_element
      remaining_path = discriminator_path

      while remaining_path.present?
        target_element, remaining_path = take_discriminator_step(target_element, remaining_path)
      end

      target_element
    end

    # rubocop:disable Metrics/CyclomaticComplexity
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
        elsif step_path.include?(' as ')
          # Handle FHIR FHIRPath "value as boolean" cast syntax (equivalent to ofType())
          base_step, cast_type = step_path.split(' as ', 2)
          target_element_path = "#{base_step.strip}[x]"
          next_element = profile_elements.find do |element|
            element.id == "#{current_element.id}.#{target_element_path}" &&
              element.type.any? { |type| type.code == cast_type.strip }
          end
        else
          next_element =
            profile_elements.find { |element| element.id == "#{current_element.id}.#{step_path}" } ||
            profile_elements.find { |element| element.id == "#{current_element.path}.#{step_path}" }
        end
      end

      [next_element, remaining_path&.delete_prefix('.')]
    end
    # rubocop:enable Metrics/CyclomaticComplexity

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
