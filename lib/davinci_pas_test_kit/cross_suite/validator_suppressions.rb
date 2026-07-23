module DaVinciPASTestKit
  # Validator message suppressions, split by suite version:
  #
  # * V221_SUPPRESSIONS is the targeted list used by the v2.2.1 suites. Each entry is anchored to a
  #   specific unactionable failure mode confirmed to still occur in current validator output
  #   (HL7 validator 6.9.x) for v2.2.1 profiles, IG examples, and test kit payloads.
  # * LEGACY_SUPPRESSIONS is the previous list, retained unchanged for the v2.0.1 suites.
  #
  # The v2.2.1 suites match only V221_SUPPRESSED_MESSAGES; the v2.0.1 suites match the union of
  # both lists (V201_SUPPRESSED_MESSAGES).
  #
  # rubocop:disable Layout/LineLength
  V221_SUPPRESSIONS = [
    # X12 value set and code system definitions are proprietary and not available to the validator,
    # so resolution failures for them are not actionable by users.
    %r{ValueSet 'https://valueset\.x12\.org/[^']+' not found},
    %r{A definition for CodeSystem 'https://codesystem\.x12\.org/[^']+' could not be found, so the code cannot be validated},
    # The NUBC revenue code system is proprietary as well and cannot be resolved. The test kit's
    # example data references it under both of the URLs the IG has used for it.
    %r{A definition for CodeSystem 'https://www\.nubc\.org/(revenue-code|CodeSystem/RevenueCodes)' could not be found, so the code cannot be validated},
    # The IG references this draft code system with bindings stronger than example.
    'Reference to draft CodeSystem http://hl7.org/fhir/us/davinci-pas/CodeSystem/PASTempCodes',
    # IG defect: these extensions are marked must-support at a location that their own context
    # definition does not permit, so the validator rejects them where the profile requires them.
    # Each pattern is anchored to the specific element context that the IG forces (reported by the
    # validator as "(this element is [...])"), so a genuinely misplaced extension is not suppressed.
    # extension-authorizationNumber/administrationReferenceNumber: context allows Claim.item only,
    # but profile-claim-base marks them must-support on Claim.extension.
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-authorizationNumber( v[\d.]+)? is not allowed to be used at this point \(this element is \[Claim\]},
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-administrationReferenceNumber( v[\d.]+)? is not allowed to be used at this point \(this element is \[Claim\]},
    # extension-infoChanged/modifierextension-infoCancelled: context lists Claim.item only, but
    # profile-claim-base marks them must-support on Claim.supportingInfo as well.
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-infoChanged( v[\d.]+)? is not allowed to be used at this point \(this element is \[(?:BackboneElement, )?Claim\.supportingInfo\]},
    %r{The modifier extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/modifierextension-infoCancelled( v[\d.]+)? is not allowed to be used at this point \(this element is \[(?:BackboneElement, )?Claim\.supportingInfo\]},
    # extension-communicatedDiagnosis: context lists Claim only, but profile-claimresponse marks it
    # must-support on ClaimResponse.item.
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-communicatedDiagnosis( v[\d.]+)? is not allowed to be used at this point \(this element is \[(?:BackboneElement, )?ClaimResponse\.item\]},
    # extension-productOrServiceCodeEnd: context lists Claim.item/ClaimResponse, but
    # profile-servicerequest marks it must-support on ServiceRequest.
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-productOrServiceCodeEnd( v[\d.]+)? is not allowed to be used at this point \(this element is \[ServiceRequest\]},
    # extension-itemAuthorizedProvider: context allows ExplanationOfBenefit/ClaimResponse.item only,
    # but profile-claimresponse marks it must-support on the ClaimResponse root.
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-itemAuthorizedProvider( v[\d.]+)? is not allowed to be used at this point \(this element is \[ClaimResponse\]},
    # extension-revenueUnitRateLimit/serviceItemRequestType/certificationType: context prohibits
    # ClaimResponse.addItem, but profile-claimresponse marks all three must-support there.
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-revenueUnitRateLimit( v[\d.]+)? is not allowed to be used at this point \(this element is \[(?:BackboneElement, )?ClaimResponse\.addItem\]},
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-serviceItemRequestType( v[\d.]+)? is not allowed to be used at this point \(this element is \[(?:BackboneElement, )?ClaimResponse\.addItem\]},
    %r{The extension http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/extension-certificationType( v[\d.]+)? is not allowed to be used at this point \(this element is \[(?:BackboneElement, )?ClaimResponse\.addItem\]}
  ].freeze

  # This list captures all validator messages suppressed for the v2.0.1 suites
  # Source: https://hl7.org/fhir/us/davinci-pas/STU2/qa.html#suppressed
  #
  # Some of the messages in this list are generated by the IG publisher and will never actually come from the
  # validator. It was simpler to leave them in than try to filter them out.
  #
  # All messages below are from the linked suppression list except the first one, which relates to the DAF IG.
  # This IG is not relevant to PAS, and so it can safely be ignored as an erroneous output from the validator
  # wrapper.
  #
  # The vast majority of these suppressions are necessary because of Da Vinci PAS profiles that require
  # ValueSets from X12. X12 is proprietary, so we cannot assume the validator has access.
  #
  # Note that some of the components below are regexes to match substrings instead of full string matching,
  # because of potential variance in the message which is expressed with a "%" in the linked suppression list.
  #
  # Also note there is a handful of messages where the official list contains the words "could not be found",
  # where the messages return from the Inferno validator serivce contain the words "is unknown". The
  # corresponding regexes below have a capturing group to account for both cases.
  LEGACY_SUPPRESSIONS = [
    "Global Profile reference 'http://hl7.org/fhir/us/core/StructureDefinition/patient' from IG http://hl7.org/fhir/us/daf|0 could not be resolved, so has not been checked",
    %r{Unable to provide support for code system http://terminology\.hl7\.org/CodeSystem/icd9cm},
    %r{Unable to provide support for code system http://www\.cms\.gov/Medicare/Coding/HCPCSReleaseCodeSets},
    %r{Unable to provide support for code system https://www\.nubc\.org/CodeSystem/TypeOfBill},
    %r{Unable to provide support for code system https://www\.nubc\.org/revenue-code},
    %r{Code System URI 'http://www\.cms\.gov/Medicare/Coding/HCPCSReleaseCodeSets' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://www\.cms\.gov/Medicare/Coding/place-of-service-codes/Place_of_Service_Code_Set' (could not be found|is unknown) so the code cannot be validated},
    "The definition for the Code System with URI 'https://www.cms.gov/Medicare/Coding/place-of-service-codes/Place_of_Service_Code_Set' doesnt provide any codes so the code cannot be validated",
    "The definition for the Code System with URI 'https://www.nubc.org/CodeSystem/PatDischargeStatus' doesnt provide any codes so the code cannot be validated",
    "The definition for the Code System with URI 'https://www.nubc.org/CodeSystem/PointOfOrigin' doesnt provide any codes so the code cannot be validated",
    "The definition for the Code System with URI 'https://www.nubc.org/CodeSystem/PriorityTypeOfAdmitOrVisit' doesnt provide any codes so the code cannot be validated",
    %r{Reference to draft item http://hl7\.org/fhir/standards-status},
    %r{Reference to draft item http://hl7\.org/fhir/us/davinci-pas/CodeSystem/PASTempCodes},
    "The resource status 'draft' and the standards status 'trial-use' may not be consistent and should be reviewed",
    %r{This element does not match any known slice defined in the profile http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-request-bundle},
    %r{This element does not match any known slice defined in the profile http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-response-bundle},
    %r{This element does not match any known slice defined in the profile http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-request-bundle},
    %r{This element does not match any known slice defined in the profile http://hl7\.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle},
    %r{Unable to check whether the code is in the value set http://hl7\.org/fhir/us/davinci-pas/ValueSet/X12278ConditionCategory},
    %r{Unable to check whether the code is in the value set http://hl7\.org/fhir/us/davinci-pas/ValueSet/X12278ConditionCode},
    %r{Unable to check whether the code is in the value set http://hl7\.org/fhir/us/davinci-pas/ValueSet/X12278FollowUpActionCodes},
    %r{Unable to check whether the code is in the value set http://hl7\.org/fhir/us/davinci-pas/ValueSet/X12278LocationType},
    %r{Unable to check whether the code is in the value set http://hl7\.org/fhir/us/davinci-pas/ValueSet/X12278NutritionOralDietType},
    %r{Unable to check whether the code is in the value set http://hl7\.org/fhir/us/davinci-pas/ValueSet/X12278RejectReasonCodes},
    %r{Unable to check whether the code is in the value set http://hl7\.org/fhir/us/davinci-pas/ValueSet/X12278RequestedServiceType},
    'US FHIR Usage rules require that all profiles on Coverage derive from the core US profile',
    'US FHIR Usage rules require that all profiles on PractitionerRole derive from the core US profile',
    'US FHIR Usage rules require that all profiles on ServiceRequest derive from the core US profile',
    %r{Unable to provide support for code system https://codesystem\.x12\.org/005010/1136},
    %r{Unable to provide support for code system https://codesystem\.x12\.org/005010/1321},
    %r{Unable to provide support for code system https://codesystem\.x12\.org/005010/1365},
    %r{Unable to provide support for code system https://codesystem\.x12\.org/005010/755},
    %r{Unable to provide support for code system https://codesystem\.x12\.org/005010/756},
    %r{Unable to provide support for code system https://codesystem\.x12\.org/005010/889},
    %r{Unable to provide support for code system https://codesystem\.x12\.org/005010/901},
    %r{Unable to provide support for code system https://codesystem\.x12\.org/external/886},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/1136' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/1321' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/1322' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/1337' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/1338' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/1345' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/1365' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/1525' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/306' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/584' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/678' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/679' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/755' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/889' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/901' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/923' (could not be found|is unknown) so the code cannot be validated},
    %r{Code System URI 'https://codesystem\.x12\.org/005010/98' (could not be found|is unknown) so the code cannot be validated},
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000D/INS/1/02/00/1069 on element Coverage.relationship.coding could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000E/CL1/1/01/00/1315 on element Encounter.type could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000E/CL1/1/02/00/1314 on element Encounter.hospitalization.admitSource could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000E/CL1/1/03/00/1352 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000E/CL1/1/04/00/1345 on element Encounter.extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000E/CR6/1/01/00/923 on element Extension.extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000E/UM/1/01/00/1525 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000E/UM/1/05/01/1362 on element Claim.accident.type could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000E/UM/1/06/00/1338 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000F/HSD/1/07/00/678 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000F/HSD/1/08/00/679 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000F/SV1/1/20/00/1337 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000F/SV2/1/09/00/1345 on element Claim.item.extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000F/UM/1/02/00/1322 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2000F/UM/1/03/00/1365 on element Claim.item.category could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2010A/NM1/1/01/00/98 on element Organization.type could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2010C/INS/1/08/00/584 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2010EA/NM1/1/01/00/98 on element Claim.careTeam.role could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2010EA/PRV/1/03/00/127 on element Claim.careTeam.qualification could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2010F/NM1/1/01/00/98 on element Claim.careTeam.role could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/request/2010F/PRV/1/03/00/127 on element Claim.careTeam.qualification could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/response/2000D/PWK/1/01/00/755 on element CommunicationRequest.category could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/response/2000F/HCR/1/01/00/306 on element Extension.value[x] could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/response/2010B/NM1/1/01/00/98 on element Organization.type could not be resolved',
    'The valueSet reference https://valueset.x12.org/x217/005010/response/2010EA/NM1/1/01/00/98 on element Extension.extension.value[x] could not be resolved',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000E/CL1/1/01/00/1315 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000E/CL1/1/02/00/1314 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000E/CL1/1/03/00/1352 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000E/CR6/1/01/00/923 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000E/UM/1/01/00/1525 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000E/UM/1/06/00/1338 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000F/HSD/1/07/00/678 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000F/HSD/1/08/00/679 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000F/SV1/1/20/00/1337 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000F/SV2/1/09/00/1345 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000F/UM/1/02/00/1322 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2000F/UM/1/03/00/1365 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2010A/NM1/1/01/00/98 not found',
    'ValueSet https://valueset.x12.org/x217/005010/request/2010C/INS/1/08/00/584 not found',
    'ValueSet https://valueset.x12.org/x217/005010/response/2000D/PWK/1/01/00/755 not found',
    'ValueSet https://valueset.x12.org/x217/005010/response/2000F/HCR/1/01/00/306 not found',
    'ValueSet https://valueset.x12.org/x217/005010/response/2010B/NM1/1/01/00/98 not found',
    # additional lines added beyond the errors suppressed in the IG
    'http://hl7.org/fhir/5.0/StructureDefinition/extension-Claim.encounter', # validator bug, https://github.com/hapifhir/org.hl7.fhir.core/issues/1556
    'X12278DiagnosisCodes', # ValueSet includes full ICD-10-CM plus unavailable code systems; validator cannot fully expand
    'X12278RequestedServiceType', # X12 code system included in this PAS-defined value set
    'X12278LocationType', # X12 code system included in this PAS-defined value set
    'ValueSet https://valueset.x12.org/x217/005010/response/2010B/NM1/1/01/00/98 not found',
    "Error from http://tx.fhir.org/r4: Error:A definition for the value Set 'http://hl7.org/fhir/us/core/ValueSet/us-core-usps-state|3.1.1' could not be found",
    "A definition for CodeSystem 'https://www.cms.gov/Medicare/Coding/place-of-service-codes/Place_of_Service_Code_Set' could not be found, so the code cannot be validated",
    "A definition for CodeSystem 'http://www.cms.gov/Medicare/Coding/HCPCSReleaseCodeSets' could not be found, so the code cannot be validated",
    'could not be found, so the code cannot be validated',
    'https://www.nubc.org/revenue-code',
    # supress references to draft code systems that the IG references with bindings stronger than example
    # looks to just be the PAS Temp Codes
    'Reference to draft CodeSystem http://hl7.org/fhir/us/davinci-pas/CodeSystem/PASTempCodes',
    # no real content
    /Details for (.+) matching against profile/,
    ': All OK',
    # This was ignored natively in the Inferno validator but needs to be ignored by the test kit with the HL7 validator
    /URL value '.*' does not resolve/,
    # addition validator clean-up based on Bundle sub-validations where Inferno error supression doesn't
    # work. The test kit validates these instances individually as well, so they are still checked,
    # but in a way that Inferno can supress errors
    'Unable to find a match for profile',
    'Unable to find a profile match for',
    # IG defect: extension context definitions for these extensions don't match where the profiles place them
    # extension-authorizationNumber context allows Claim.item only, but profile-claim-base marks it must-support on Claim.extension
    /extension-authorizationNumber( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    /extension-administrationReferenceNumber( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    /extension-communicatedDiagnosis( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    # IG defect: extension-productOrServiceCodeEnd context only lists Claim.item/ClaimResponse, but profile-servicerequest marks it must-support on ServiceRequest
    /extension-productOrServiceCodeEnd( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    # IG defect: extension-infoChanged and modifierextension-infoCancelled context only lists Claim.item,
    # but profile-claim-base marks them must-support on Claim.supportingInfo as well
    /extension-infoChanged( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    /modifierextension-infoCancelled( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    # IG defect: extension-itemAuthorizedProvider context allows ExplanationOfBenefit/ClaimResponse.item only,
    # but profile-claimresponse marks ClaimResponse.extension:authorizedProvider as must-support on ClaimResponse root
    /extension-itemAuthorizedProvider( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    # IG defect: extension-revenueUnitRateLimit, extension-serviceItemRequestType, extension-certificationType
    # context prohibits ClaimResponse.addItem, but profile-claimresponse marks all three as must-support there
    /extension-revenueUnitRateLimit( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    /extension-serviceItemRequestType( v\d+\.\d+\.\d+)? is not allowed to be used at this point/,
    /extension-certificationType( v\d+\.\d+\.\d+)? is not allowed to be used at this point/
  ].freeze
  # rubocop:enable Layout/LineLength

  V221_SUPPRESSED_MESSAGES = Regexp.union(V221_SUPPRESSIONS)
  V201_SUPPRESSED_MESSAGES = Regexp.union(LEGACY_SUPPRESSIONS + V221_SUPPRESSIONS)
end
