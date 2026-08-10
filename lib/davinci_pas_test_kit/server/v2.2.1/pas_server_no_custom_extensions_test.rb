require_relative '../../cross_suite/tags'

module DaVinciPASTestKit
  module DaVinciPASV221
    class PasNoCustomExtensionsTest < Inferno::Test
      US_CORE_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-direct',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
        'http://hl7.org/fhir/us/core/StructureDefinition/uscdi-requirement',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-extension-questionnaire-uri',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-genderIdentity',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-jurisdiction',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-sex',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-tribal-affiliation',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication-adherence',
        'http://hl7.org/fhir/StructureDefinition/condition-assertedDate'
      ].freeze

      CRD_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/ext-coverage-information',
        'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/ext-billing-options',
        'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/ext-request-category',
        'http://hl7.org/fhir/StructureDefinition/codeOptions',
        'http://hl7.org/fhir/StructureDefinition/alternate-reference',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-CommunicationRequest.payload.content',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.requestedPeriod',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.requestedPerformer',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.performer',
        'http://hl7.org/fhir/StructureDefinition/request-doNotPerform',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.input.value',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.output.value',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.statusReason'
      ].freeze

      HREX_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/davinci-hrex/StructureDefinition/extension-CoverageDavinciWellknownLocation'
      ].freeze

      DTR_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/activeRole',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/alternativeExpression',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/containedReference',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/intendedUse',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/qr-context',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/estimated-completion-time',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/questionnaireAudience',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/qr-coverage',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/request-specific'
      ].freeze

      PAS_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-TransmissionIdentifiers',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-administrationReferenceNumber',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-admissionDates',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-authorizationNumber',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-authorizedProviderType',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-careTeamClaimScope',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-certificationType',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-claimResponseReviewer',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-communicatedDiagnosis',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-conditionCode',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-contentModifier',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-diagnosisRecordedDate',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-dischargeDate',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-documentInformation',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-epsdtIndicator',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-errorElement',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-errorFollowupAction',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-errorPath',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-homeHealthCareInformation',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-identifierJurisdiction',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-identifierSubDepartment',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-infoChanged',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemAuthorizedDetail',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemAuthorizedProvider',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemCategory',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemCertificationEffectiveDate',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemCertificationExpirationDate',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemCertificationIssueDate',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemPreAuthIssueDate',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemPreAuthPeriod',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemRequestedServiceDate',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemTraceNumber',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-levelOfServiceCode',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-militaryStatus',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-nursingHomeLevelOfCare',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-nursingHomeResidentialStatus',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-patientStatus',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-productOrServiceCodeEnd',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-requestedService',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-revenueCode',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-revenueUnitRateLimit',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-serviceItemRequestType',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-serviceLineNumber',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-timingcalendarpattern',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-timingdeliverypattern',
        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/modifierextension-infoCancelled',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Claim.encounter',
        'http://hl7.org/fhir/StructureDefinition/data-absent-reason',
        'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-filter-criteria',
        'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-heartbeat-period',
        'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-timeout',
        'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-max-count',
        'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-channel-type',
        'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-payload-content',
        'http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/capabilitystatement-subscriptiontopic-canonical'
      ].freeze

      SDC_EXTENSION_URLS = [
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-answerExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-answerOptionsToggleExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assemble-expectation',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assembleContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assembleDefinitionRoot',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assembledFrom',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-choiceColumn',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-collapsible',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-columnCount',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-endpoint',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-entryMode',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-extractAllocateId',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-isSubject',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemAnswerMedia',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemExtractionContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemMedia',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemPopulationContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-keyboard',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-lookupQuestionnaire',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-maxQuantity',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-minQuantity',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observation-extract-category',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observationExtract',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observationExtractEntry',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observationLinkPeriod',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-openLabel',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-optionalDisplay',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-performerType',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-preferredTerminologyServer',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-shortText',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-sourceQueries',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-sourceStructureMap',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-subQuestionnaire',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-targetStructureMap',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtract',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractBundle',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractValue',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-unitOpen',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-unitSupplementalSystem',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-width',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-isSubject',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-rendering-criticalExtension',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-servicerequest-questionnaire'
      ].freeze

      VALID_EXTENSION_URLS = (US_CORE_EXTENSION_URLS + CRD_EXTENSION_URLS + HREX_EXTENSION_URLS \
        + SDC_EXTENSION_URLS + DTR_EXTENSION_URLS + PAS_EXTENSION_URLS).freeze

      id :pas_server_v221_no_custom_extensions_test
      title 'Server processes $submit without custom extensions'
      description %(
        This test verifies that the server is capable of responding to a client
        without the use of any custom extensions. It inspects each successful
        PAS submission, and if it finds one which doesn't use any extensions
        not defined by FHIR, US Core, PAS, CRD, DTR, or HRex it passes.
      )

      verifies_requirements 'hl7.fhir.us.davinci-pas_2.2.1@conf-11'

      run do
        requests = load_tagged_requests(SUBMIT_TAG)
        skip_if requests.blank?, 'No requests were made in a previous test as expected.'

        successful_requests = requests.select { |request| request.status == 200 }
        skip_if successful_requests.empty?, 'All service requests were unsuccessful.'

        bundles = successful_requests.filter_map { |request| bundle_from_request(request) }
        skip_if bundles.empty?, 'No PAS Request Bundles were found in successful submissions.'

        request_with_no_custom_extensions = bundles.any? { |bundle| no_custom_extensions?(bundle) }

        pass_if request_with_no_custom_extensions

        custom_extensions_string =
          bundles
            .flat_map { |bundle| custom_extensions(bundle) }
            .uniq
            .map { |extension| "\n- `#{extension}`" }
            .join

        skip 'No requests were made without custom extensions. The following custom extensions were found: ' \
             "#{custom_extensions_string}"
      end

      def bundle_from_request(request)
        resource = FHIR.from_contents(request.request_body)
        resource if resource.is_a?(FHIR::Bundle)
      rescue JSON::ParserError
        nil
      end

      def no_custom_extensions?(bundle)
        bundle.each_element do |value, _metadata, path|
          next unless value.is_a?(FHIR::Extension)

          next if path.to_s.scan('extension').length > 1

          return false unless VALID_EXTENSION_URLS.include?(value.url.to_s)
        end

        true
      end

      def custom_extensions(bundle)
        [].tap do |custom_extensions|
          bundle.each_element do |value, _metadata, path|
            next unless value.is_a?(FHIR::Extension)

            next if path.to_s.scan('extension').length > 1

            custom_extensions << value.url.to_s unless VALID_EXTENSION_URLS.include?(value.url.to_s)
          end
        end
      end
    end
  end
end
