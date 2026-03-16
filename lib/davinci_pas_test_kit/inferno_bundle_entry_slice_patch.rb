require 'inferno/dsl/fhir_resource_navigation'
require 'inferno/dsl/must_support_assessment'

module Inferno
  module DSL
    module FHIRResourceNavigation
      private

      def normalize_extension_url(url)
        url.to_s.split('|').first
      end

      def extension_url_matches?(actual_url, expected_url)
        normalize_extension_url(actual_url) == normalize_extension_url(expected_url)
      end

      def extension_selector_url(property)
        property.to_s[/(?<=where\(url=').*(?='\))/] ||
          property.to_s[/\A(?:extension|modifierExtension)\('([^']+)'\)\z/, 1]
      end

      def extension_value(element)
        value_field =
          element.source_hash&.keys&.find do |key|
            key.start_with?('value') && key != 'value'
          end

        return nil if value_field.blank?

        element.send(local_field_name(value_field))
      end

      def value_matches_of_type?(value, type_name)
        case type_name.to_s.downcase
        when 'boolean'
          [true, false].include?(value)
        when 'string'
          value.is_a?(String)
        when 'date'
          value.is_a?(Date) || value.is_a?(FHIR::Date)
        when 'datetime'
          value.is_a?(DateTime) || value.is_a?(FHIR::DateTime)
        else
          value.is_a?(FHIR.const_get(type_name.to_s.camelize))
        end
      rescue NameError
        false
      end

      def extension_slice_value(element, property)
        extension_type, extension_name = property.to_s.split(':', 2)
        return nil unless %w[extension modifierExtension].include?(extension_type)
        return nil unless metadata.present?

        extension_definition =
          metadata.must_supports[:extensions].find do |definition|
            definition[:id].end_with?("#{extension_type}:#{extension_name}")
          end

        return nil if extension_definition.blank?

        extensions = Array.wrap(element.send(local_field_name(extension_type)))
        extensions.find { |extension| extension_url_matches?(extension.url, extension_definition[:url]) }
      end

      def supporting_info_slice_code(slice_name)
        {
          'PatientEvent' => 'patientEvent',
          'AdmissionDates' => 'admissionDates',
          'DischargeDates' => 'dischargeDates',
          'AdditionalInformation' => 'additionalInformation',
          'MessageText' => 'freeFormMessage'
        }[slice_name.to_s]
      end

      def supporting_info_slice_value(element, slice_name)
        code = supporting_info_slice_code(slice_name)
        return nil if code.blank?

        supporting_info = Array.wrap(element.supportingInfo)
        supporting_info.find do |info|
          Array.wrap(info.category&.coding).any? do |coding|
            coding.system == 'http://hl7.org/fhir/us/davinci-pas/CodeSystem/PASTempCodes' &&
              coding.code == code
          end
        end
      end

      # Bundle.entry type slices discriminate on the embedded resource type.
      # Inferno's generic navigation checks the entry object itself here,
      # which misses slices like entry:ClaimResponse.fullUrl/resource.
      def matching_type_slice?(slice, discriminator)
        slice_value = resolve_path(slice, discriminator[:path]).first

        case discriminator[:code]
        when 'Date'
          begin
            Date.parse(slice_value)
          rescue ArgumentError
            false
          end
        when 'DateTime'
          begin
            DateTime.parse(slice_value)
          rescue ArgumentError
            false
          end
        when 'String'
          slice_value.is_a? String
        else
          slice_value = slice_value.resource if slice_value.is_a?(FHIR::Bundle::Entry)
          slice_value.is_a? FHIR.const_get(discriminator[:code])
        end
      end

      # Some generated bindings omit their expanded value set entries.
      # Fall back to detecting an X12 coding so X12Code slices can still match.
      def matching_required_binding_slice?(slice, discriminator)
        slice_value = discriminator[:path].present? ? slice.send(discriminator[:path].to_s) : slice
        slice_coding = slice_value.respond_to?(:coding) ? Array.wrap(slice_value.coding) : Array.wrap(slice_value)

        if discriminator[:values].blank?
          slice_coding.any? { |coding| coding.system&.include?('x12.org') }
        else
          slice_coding.any? do |coding|
            discriminator[:values].any? do |value|
              case value
              when String
                value == coding.code
              when Hash
                value[:system] == coding.system && value[:code] == coding.code
              end
            end
          end
        end
      end

      def matching_value_slice?(slice, discriminator)
        values =
          discriminator[:values].map do |value|
            value.merge(path: value[:path].split(/(?<!hl7)\./))
          end
        verify_slice_by_values(slice, values)
      end

      def matching_slice?(slice, discriminator)
        case discriminator[:type]
        when 'patternCodeableConcept'
          matching_pattern_codeable_concept_slice?(slice, discriminator)
        when 'patternCoding'
          matching_pattern_coding_slice?(slice, discriminator)
        when 'patternIdentifier'
          matching_pattern_identifier_slice?(slice, discriminator)
        when 'value'
          matching_value_slice?(slice, discriminator)
        when 'type'
          matching_type_slice?(slice, discriminator)
        when 'requiredBinding'
          matching_required_binding_slice?(slice, discriminator)
        when 'unsupported'
          find_a_value_at(slice, discriminator[:path].to_s) == false
        end
      end

      def get_next_value(element, property)
        selected_extension_url = extension_selector_url(property)
        if selected_extension_url.present?
          handle_extension_selector(element, property, selected_extension_url)
        elsif property.to_s == 'value' && element.is_a?(FHIR::Extension)
          extension_value(element)
        elsif property.to_s.match?(/\AofType\((.+)\)\z/)
          handle_of_type(element, property)
        elsif property.to_s.include?(':') && !property.to_s.include?('url')
          handle_slice_property(element, property)
        else
          handle_standard_property(element, property)
        end
      rescue NoMethodError
        nil
      end

      def handle_extension_selector(element, property, selected_extension_url)
        if property.to_s.start_with?('extension(') || property.to_s.start_with?('modifierExtension(')
          extension_type = property.to_s.start_with?('modifierExtension(') ? 'modifierExtension' : 'extension'
          extensions = Array.wrap(element.send(local_field_name(extension_type)))
          extensions.find { |extension| extension_url_matches?(extension.url, selected_extension_url) }
        elsif element.url && extension_url_matches?(element.url, selected_extension_url)
          element
        end
      end

      def handle_of_type(element, property)
        type_name = property.to_s[/\AofType\((.+)\)\z/, 1]
        value_matches_of_type?(element, type_name) ? element : nil
      end

      def handle_slice_property(element, property)
        extension_value = extension_slice_value(element, property)
        return extension_value unless extension_value.nil?

        slice_value = find_slice_via_discriminator(element, property)
        return slice_value unless slice_value.nil?

        element_name, slice_name = property.to_s.split(':', 2)
        return unless element_name.present? && slice_name.present? && element.respond_to?(local_field_name(slice_name))

        element.send(local_field_name(slice_name))
      end

      def handle_standard_property(element, property)
        local_name = local_field_name(property)
        value = element.send(local_name)
        primitive_value = get_primitive_type_value(element, property, value)
        primitive_value.present? ? primitive_value : value
      end

      def find_slice_via_discriminator(element, property)
        return unless metadata.present?

        element_name = local_field_name(property.to_s.split(':')[0])
        slice_name = local_field_name(property.to_s.split(':')[1])

        slice_by_name = metadata.must_supports[:slices].find { |slice| slice[:slice_name] == slice_name }
        if slice_by_name.blank? && element_name == 'supportingInfo'
          return supporting_info_slice_value(element,
                                             slice_name)
        end
        return nil if slice_by_name.blank?

        discriminator = slice_by_name[:discriminator]
        slices = Array.wrap(element.send(element_name))
        slices.find { |slice| matching_slice?(slice, discriminator) }
      end
    end

    module MustSupportAssessment
      class InternalMustSupportLogic
        private

        def extension_url_matches?(actual_url, expected_url)
          normalize_extension_url(actual_url) == normalize_extension_url(expected_url)
        end

        def normalize_extension_url(url)
          url.to_s.split('|').first
        end

        def missing_extensions(resources = [])
          @missing_extensions ||=
            must_support_extensions.select do |extension_definition|
              resources.none? do |resource|
                path = extension_definition[:path]

                if path == 'extension'
                  resource.extension.any? do |extension|
                    extension_url_matches?(extension.url, extension_definition[:url])
                  end
                else
                  extension = find_a_value_at(resource, path) do |el|
                    extension_url_matches?(el.url, extension_definition[:url])
                  end

                  extension.present?
                end
              end
            end
        end

        def process_must_support_element_in_extension(resource, path)
          return [resource, path] unless path.start_with?('extension:')

          path_without_prefix = path.delete_prefix('extension:')
          extension_split = path_without_prefix.split('.')
          extension_name = extension_split.first
          extension_path = extension_split.last

          found_extension_url = must_support_extensions.find { |ex| ex[:id].include?(extension_name) }[:url]
          ms_element_extension = resource.extension.find { |ex| extension_url_matches?(ex.url, found_extension_url) }

          if ms_element_extension.present?
            resource = ms_element_extension
            path = extension_path
          end

          [resource, path]
        end

        def matching_without_extensions?(value, ms_extension_urls, fixed_value)
          if value.instance_of?(Inferno::DSL::PrimitiveType)
            urls = value.extension&.map { |ext| normalize_extension_url(ext.url) }
            normalized_ms_extension_urls = ms_extension_urls.map { |url| normalize_extension_url(url) }
            has_ms_extension = (urls & normalized_ms_extension_urls).present?
            value = value.value
          end

          return false unless has_ms_extension || value_without_extensions?(value)

          matches_fixed_value?(value, fixed_value)
        end

        def find_slice(resource, path, discriminator)
          find_a_value_at(resource, path) do |element|
            case discriminator[:type]
            when 'patternCodeableConcept'
              find_pattern_codeable_concept_slice(element, discriminator)
            when 'patternCoding'
              find_pattern_coding_slice(element, discriminator)
            when 'patternIdentifier'
              find_pattern_identifier_slice(element, discriminator)
            when 'value'
              find_value_slice(element, discriminator)
            when 'type'
              find_type_slice(element, discriminator)
            when 'requiredBinding'
              find_required_binding_slice(element, discriminator)
            when 'unsupported'
              find_a_value_at(element, discriminator[:path].to_s) == false
            end
          end
        end

        def find_value_slice(element, discriminator)
          values =
            discriminator[:values].map do |value|
              value.merge(path: value[:path].split(/(?<!hl7)\./))
            end

          find_slice_by_values(element, values)
        end

        def find_required_binding_slice(element, discriminator)
          slice_value = discriminator[:path].present? ? element.send(discriminator[:path].to_s) : element
          slice_coding = slice_value.respond_to?(:coding) ? Array.wrap(slice_value.coding) : Array.wrap(slice_value)

          slice_coding.find do |coding|
            if discriminator[:values].blank?
              coding.system&.include?('x12.org')
            else
              discriminator[:values].any? do |value|
                case value
                when String
                  value == coding.code
                when Hash
                  value[:system] == coding.system && value[:code] == coding.code
                end
              end
            end
          end
        end
      end
    end
  end
end
