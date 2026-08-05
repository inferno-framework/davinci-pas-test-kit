module DaVinciPASTestKit
  # Checks for the narrative-only constraints on the PAS Timing and Quantity data type
  # profiles introduced in v2.2 (prof-1, prof-2, prof-3). These constraints have no
  # FHIRPath expression in the StructureDefinitions, so the FHIR validator cannot
  # enforce them and they are verified here instead.
  # See https://hl7.org/fhir/us/davinci-pas/STU2.2/StructureDefinition-profile-datatype-timing.html
  # and https://hl7.org/fhir/us/davinci-pas/STU2.2/StructureDefinition-profile-quantity.html
  module PasDatatypeConstraints
    PAS_STRUCTURE_DEFINITION_BASE = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition'

    TIMING_CALENDAR_PATTERN_EXTENSION_URL = "#{PAS_STRUCTURE_DEFINITION_BASE}/extension-timingcalendarpattern".freeze
    TIMING_DELIVERY_PATTERN_EXTENSION_URL = "#{PAS_STRUCTURE_DEFINITION_BASE}/extension-timingdeliverypattern".freeze
    ITEM_AUTHORIZED_DETAIL_EXTENSION_URL = "#{PAS_STRUCTURE_DEFINITION_BASE}/extension-itemAuthorizedDetail".freeze

    # Quantity.code is bound (required) to the X12 673 "quantity qualifier" value set,
    # which the terminology validator cannot expand. Requiring this system when a code
    # is present is the machine-checkable part of prof-3.
    X12_QUANTITY_UNITS_SYSTEM = 'https://codesystem.x12.org/005010/673'

    # Profiles that apply profile-datatype-timing to elements of their resource.
    TIMING_CONSTRAINED_PROFILE_URLS = [
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-devicerequest",
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-medicationrequest",
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-servicerequest"
    ].freeze

    # Profiles that apply profile-quantity to elements of their resource, directly or
    # inherited from profile-claim-base (Claim.item.quantity) and
    # profile-claimresponse-base (ClaimResponse.addItem.quantity and the
    # itemAuthorizedDetail quantity sub-extension).
    QUANTITY_CONSTRAINED_PROFILE_URLS = [
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-claim",
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-claim-update",
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-claim-inquiry",
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-claimresponse",
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-claiminquiryresponse",
      "#{PAS_STRUCTURE_DEFINITION_BASE}/profile-servicerequest"
    ].freeze

    # Evaluates the PAS data type profile constraints for a resource against a profile.
    # @param resource [FHIR::Model] The resource being validated.
    # @param profile_url [String] The canonical (unversioned) profile URL being validated against.
    # @param version [String] The IG version.
    # @return [Array<Hash>] Error message hashes for each constraint violation found.
    def datatype_constraint_messages(resource, profile_url, version)
      return [] unless pas_datatype_constraints_enabled?(version)

      constraint_messages = []
      if TIMING_CONSTRAINED_PROFILE_URLS.include?(profile_url)
        profiled_timing_elements(resource).each do |timing, location|
          constraint_messages << timing_prof1_message(resource, timing, location)
        end
      end
      if QUANTITY_CONSTRAINED_PROFILE_URLS.include?(profile_url)
        profiled_quantity_elements(resource).each do |quantity, location|
          constraint_messages << quantity_prof2_message(resource, quantity, location)
          constraint_messages << quantity_prof3_message(resource, quantity, location)
        end
      end
      constraint_messages.compact
    end

    # The Timing and Quantity data type profiles were introduced in PAS v2.2.
    def pas_datatype_constraints_enabled?(version)
      version.to_s.delete_prefix('v').match?(/\A2\.2(\.|\z)/)
    end

    private

    # Timing instances the PAS profiles constrain, paired with their element locations.
    def profiled_timing_elements(resource)
      case resource.resourceType
      when 'DeviceRequest', 'ServiceRequest'
        timing = resource.occurrenceTiming
        timing.present? ? [[timing, "#{resource.resourceType}.occurrenceTiming"]] : []
      when 'MedicationRequest'
        Array(resource.dosageInstruction).each_with_index.filter_map do |dosage, index|
          [dosage.timing, "MedicationRequest.dosageInstruction[#{index}].timing"] if dosage.timing.present?
        end
      else
        []
      end
    end

    # Quantity instances the PAS profiles constrain, paired with their element locations.
    def profiled_quantity_elements(resource)
      case resource.resourceType
      when 'Claim'
        Array(resource.item).each_with_index.filter_map do |item, index|
          [item.quantity, "Claim.item[#{index}].quantity"] if item.quantity.present?
        end
      when 'ClaimResponse'
        claim_response_quantity_elements(resource)
      when 'ServiceRequest'
        quantity = resource.quantityQuantity
        quantity.present? ? [[quantity, 'ServiceRequest.quantityQuantity']] : []
      else
        []
      end
    end

    def claim_response_quantity_elements(resource)
      add_item_quantities = Array(resource.addItem).each_with_index.filter_map do |add_item, index|
        [add_item.quantity, "ClaimResponse.addItem[#{index}].quantity"] if add_item.quantity.present?
      end

      authorized_detail_quantities = Array(resource.item).each_with_index.flat_map do |item, index|
        Array(item.extension)
          .select { |extension| extension.url == ITEM_AUTHORIZED_DETAIL_EXTENSION_URL }
          .filter_map do |extension|
            quantity = Array(extension.extension).find { |sub| sub.url == 'quantity' }&.valueQuantity
            if quantity.present?
              [quantity, "ClaimResponse.item[#{index}].extension:authorizedItemDetail.extension:quantity.value"]
            end
          end
      end

      add_item_quantities + authorized_detail_quantities
    end

    # prof-1: Timings SHALL have at least one of: a count, a frequency and period and
    # periodUnit (with optional frequencyMax and periodMax), a calendarPattern, or a
    # deliveryPattern.
    def timing_prof1_message(resource, timing, location)
      repeat = timing.repeat
      return if repeat&.count.present?
      return if repeat&.frequency.present? && repeat.period.present? && repeat.periodUnit.present?
      return if extension_present?(timing, TIMING_CALENDAR_PATTERN_EXTENSION_URL)
      return if extension_present?(timing, TIMING_DELIVERY_PATTERN_EXTENSION_URL)

      datatype_constraint_message(resource, location,
                                  'Timings SHALL have at least one of: a count, a frequency and period and ' \
                                  'periodUnit (with optional frequencyMax and periodMax), a calendarPattern, ' \
                                  'or a deliveryPattern (prof-1)')
    end

    # prof-2: Quantities SHALL have a value and either a unit or a code.
    def quantity_prof2_message(resource, quantity, location)
      return if quantity.value.present? && (quantity.unit.present? || quantity.code.present?)

      datatype_constraint_message(resource, location,
                                  'Quantities SHALL have a value and either a unit or a code (prof-2)')
    end

    # prof-3: If a quantity code is present, it SHALL use the X12 quantity units.
    def quantity_prof3_message(resource, quantity, location)
      return if quantity.code.blank? || quantity.system == X12_QUANTITY_UNITS_SYSTEM

      datatype_constraint_message(resource, location,
                                  'If a quantity code is present, it SHALL use the X12 quantity units ' \
                                  "(system #{X12_QUANTITY_UNITS_SYSTEM}) (prof-3)")
    end

    def extension_present?(element, url)
      Array(element.extension).any? { |extension| extension.url == url }
    end

    # Mirrors the "ResourceType/id: location: message" format of validator messages.
    def datatype_constraint_message(resource, location, description)
      resource_label = resource.id.present? ? "#{resource.resourceType}/#{resource.id}" : resource.resourceType
      { type: 'error', message: "#{resource_label}: #{location}: #{description}" }
    end
  end
end
