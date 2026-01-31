require_relative '../../../../cross_suite/must_support/must_support_test'

module DaVinciPASTestKit
  module DaVinciPASV201
    class ServerInquireResponseMustSupportBeneficiaryTest < DaVinciPASTestKit::MustSupportTest
      id :pas_server_v201_inquire_response_must_support_beneficiary
      title 'All must support elements for Profile PAS Beneficiary Patient are observed across all instances returned'
      description %(
        
        PAS server systems are required to be able to populate all
        must support elements on instances of all profiles included in 
        responses, including instances of the PAS Beneficiary Patient Profile.
        This test checks all identified instances of the PAS Beneficiary Patient
        Profile on responses returned by the server to ensure that the following
        must support elements are observed:

        * Patient.address
        * Patient.address.city
        * Patient.address.country
        * Patient.address.district
        * Patient.address.line
        * Patient.address.period
        * Patient.address.postalCode
        * Patient.address.state
        * Patient.birthDate
        * Patient.communication
        * Patient.communication.language
        * Patient.extension:birthsex
        * Patient.extension:ethnicity
        * Patient.extension:race
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
        * Patient.telecom
        * Patient.telecom.system
        * Patient.telecom.use
        * Patient.telecom.value
      )
      verifies_requirements 'hl7.fhir.us.davinci-pas_2.0.1@38'

      config(
        options: {
          resource_type: 'Patient',
          profile_key: 'beneficiary',
          user_input_validation: false,
          ig_version: 'v2.0.1',
          type: 'response',
          operation: 'inquire'
        }
      )
    end
  end
end
