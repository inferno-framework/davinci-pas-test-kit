module DaVinciPASTestKit
  # Removes extensions not published by HL7 from data that Inferno, acting as the payer, copies from a
  # request into a response, since Inferno doesn't send custom extensions - see NO_CUSTOM_EXTENSIONS_VALIDATOR.
  module CustomExtensionRemoval
    HL7_EXTENSION_URL_PREFIX = 'http://hl7.org/fhir/'.freeze

    # @param extension [Hash] a parsed FHIR Extension.
    def self.hl7_extension?(extension)
      extension.is_a?(Hash) && extension['url'].to_s.start_with?(HL7_EXTENSION_URL_PREFIX)
    end

    # @param value [Hash, Array, Object] parsed FHIR JSON.
    # @return a copy of the value without extensions (at any depth) that aren't published by HL7.
    #   Kept extensions are left whole, since complex extensions' sub-extensions use relative urls.
    def self.without_custom_extensions(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, child), result|
          if %w[extension modifierExtension].include?(key)
            kept = child.select { |extension| hl7_extension?(extension) }
            result[key] = kept if kept.present?
          else
            result[key] = without_custom_extensions(child)
          end
        end
      when Array
        value.map { |child| without_custom_extensions(child) }
      else
        value
      end
    end
  end
end
