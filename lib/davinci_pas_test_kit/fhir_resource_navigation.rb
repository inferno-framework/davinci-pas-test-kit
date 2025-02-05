# frozen_string_literal: true

require 'json'

module DaVinciPASTestKit
  module FHIRResourceNavigation
    DAR_EXTENSION_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'

    def resolve_path(elements, path)
      elements = Array.wrap(elements)
      return elements if path.blank?

      paths = path.split('.')
      segment = paths.first
      remaining_path = paths.drop(1).join('.')

      elements.flat_map do |element|
        child = get_next_value(element, segment)
        resolve_path(child, remaining_path)
      end.compact
    end

    def find_a_value_at(element, path, include_dar: false, &)
      return nil if element.nil?

      elements = Array.wrap(element)

      if path.blank?
        unless include_dar
          elements = elements.reject do |el|
            el.respond_to?(:extension) && el.extension.any? { |ext| ext.url == DAR_EXTENSION_URL }
          end
        end

        return elements.find(&) if block_given?

        return elements.first
      end

      path_segments = path.split('.')
      segment = path_segments.shift.delete_suffix('[x]').to_sym

      no_elements_present =
        elements.none? do |elmt|
          child = get_next_value(elmt, segment)
          child.present? || child == false
        end

      return nil if no_elements_present

      remaining_path = path_segments.join('.')
      elements.each do |elmt|
        child = get_next_value(elmt, segment)
        element_found = if block_given?
                          find_a_value_at(child, remaining_path, include_dar:, &block)
                        else
                          find_a_value_at(child, remaining_path, include_dar:)
                        end

        return element_found if element_found.present? || element_found == false
      end

      nil
    end

    def get_next_value(element, property)
      element.send(property)
    rescue NoMethodError
      nil
    end
  end
end
