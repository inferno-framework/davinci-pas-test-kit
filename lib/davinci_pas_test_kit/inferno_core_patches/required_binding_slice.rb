require 'inferno/dsl/fhir_resource_navigation'
require 'inferno/dsl/must_support_assessment'

module DaVinciPASTestKit
  module InfernoCorePatches
    module RequiredBindingSlice
      X12_SYSTEM_FRAGMENT = 'x12.org'.freeze

      module_function

      def x12_required_binding_match?(coding)
        coding.system&.include?(X12_SYSTEM_FRAGMENT)
      end

      module RequiredBindingValueMatch
        private

        def required_binding_value_match?(coding, values)
          if values.blank?
            return DaVinciPASTestKit::InfernoCorePatches::RequiredBindingSlice.x12_required_binding_match?(coding)
          end

          super
        end
      end
    end
  end
end

Inferno::DSL::FHIRResourceNavigation.prepend(
  DaVinciPASTestKit::InfernoCorePatches::RequiredBindingSlice::RequiredBindingValueMatch
)
Inferno::DSL::MustSupportAssessment::InternalMustSupportLogic.prepend(
  DaVinciPASTestKit::InfernoCorePatches::RequiredBindingSlice::RequiredBindingValueMatch
)
