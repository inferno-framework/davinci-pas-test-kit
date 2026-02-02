require 'inferno/dsl/must_support_metadata_extractor'

module DaVinciPASTestKit
  # The MustSupportMetadataExtractor takes a StructureDefinition and parses it into a hash-based metadata
  #  that simplifies checking for MustSupport elements.
  # MustSupport elements may be either plain elements, extensions, or slices.
  # This logic was originally developed for the US Core Test Kit and has been migrated into Inferno core.
  class PASMustSupportMetadataExtractor < Inferno::DSL::MustSupportMetadataExtractor
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

            if pattern_element.fixed.present?
              fixed_values << {
                path: discriminator_path,
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
