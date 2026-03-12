require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV220
    class ClientSubmitResponseMustSupportBeneficiaryTest < DaVinciPASTestKit::MustSupportTest
      id :pas_client_v220_submit_response_must_support_beneficiary
      title 'All must support elements for Profile PAS Beneficiary Patient are observed across all instances returned'
      description %(
        
        PAS client systems are required to be able to receive all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Beneficiary Patient Profile.
        This test checks all identified instances of the PAS Beneficiary Patient
        Profile on responses sent to the client to ensure that the following
        must support elements are observed:

        * Patient.address
        * Patient.address.city
        * Patient.address.country
        * Patient.address.district
        * Patient.address.line
        * Patient.address.postalCode
        * Patient.address.state
        * Patient.birthDate
        * Patient.communication.language
        * Patient.gender
        * Patient.identifier
        * Patient.identifier.system
        * Patient.identifier.value
        * Patient.multipleBirth[x]:multipleBirthInteger
        * Patient.name
        * Patient.name.family
        * Patient.name.given
        * Patient.name.prefix
        * Patient.name.suffix
        * Patient.telecom.system
        * Patient.telecom.use
        * Patient.telecom.value
      )

      config(
        options: {
          resource_type: 'Patient',
          profile_key: 'beneficiary',
          user_input_validation: true,
          ig_version: 'v2.2.0',
          type: 'response',
          operation: 'submit'
        }
      )
    end
  end
end