require_relative '../user_input_response'

module DaVinciPASTestKit
  class ClaimEndpoint < Inferno::DSL::SuiteEndpoint
    def test_run_identifier
      request.headers['authorization']&.delete_prefix('Bearer ')
    end

    def tags
      [operation == 'submit' ? SUBMIT_TAG : INQUIRE_TAG]
    end

    def make_response
      response.status = 200
      response.format = :json

      user_inputted_response = UserInputResponse.user_inputted_response(test, result)
      if user_inputted_response.present?
        response.body = user_inputted_response
        return
      end

      req_bundle = FHIR.from_contents(request.body.string)
      claim_entry = req_bundle&.entry&.find { |e| e&.resource&.resourceType == 'Claim' }
      claim_full_url = claim_entry&.fullUrl
      if claim_entry.blank? || claim_full_url.blank?
        handle_missing_required_elements(claim_entry, response)
        return
      end

      root_url = base_url(claim_full_url)
      claim_response = mock_claim_response(claim_entry.resource, req_bundle, root_url)

      res_bundle = FHIR::Bundle.new(
        id: SecureRandom.uuid,
        meta: FHIR::Meta.new(profile: if operation == 'submit'
                                        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-response-bundle'
                                      else
                                        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-pas-inquiry-response-bundle'
                                      end),
        timestamp: Time.now.utc.iso8601,
        type: 'collection',
        entry: [
          FHIR::Bundle::Entry.new(fullUrl: "urn:uuid:#{claim_response.id}",
                                  resource: claim_response)
        ]
      )

      res_bundle.entry.concat(referenced_entities(claim_response, req_bundle.entry, root_url))

      response.body = res_bundle.to_json
    end

    def update_result
      results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
    end

    private

    # Note that references from the claim to other resources in the bundle need to be changed to absolute URLs
    # if they are relative, because the ClaimResponse's fullUrl is a urn:uuid
    #
    # @private
    def mock_claim_response(claim, bundle, root_url)
      return FHIR::ClaimResponse.new(id: SecureRandom.uuid) if claim.blank?

      now = Time.now.utc

      FHIR::ClaimResponse.new(
        id: SecureRandom.uuid,
        meta: FHIR::Meta.new(profile: if operation == 'submit'
                                        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claimresponse'
                                      else
                                        'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-claiminquiryresponse'
                                      end),
        identifier: claim.identifier,
        type: claim.type,
        status: claim.status,
        use: claim.use,
        patient: absolute_reference(claim.patient, bundle.entry, root_url),
        created: now.iso8601,
        insurer: absolute_reference(claim.insurer, bundle.entry, root_url),
        requestor: absolute_reference(claim.provider, bundle.entry, root_url),
        outcome: 'complete',
        item: claim.item.map do |item|
          FHIR::ClaimResponse::Item.new(
            extension: [
              FHIR::Extension.new(
                url: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemPreAuthIssueDate',
                valueDate: now.strftime('%Y-%m-%d')
              ),
              FHIR::Extension.new(
                url: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-itemPreAuthPeriod',
                valuePeriod: FHIR::Period.new(start: now.strftime('%Y-%m-%d'),
                                              end: (now + 1.month).strftime('%Y-%m-%d'))
              )
            ],
            itemSequence: item.sequence,
            adjudication: [
              FHIR::ClaimResponse::Item::Adjudication.new(
                extension: [
                  FHIR::Extension.new(
                    url: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction',
                    extension: [
                      FHIR::Extension.new(
                        url: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode',
                        valueCodeableConcept: FHIR::CodeableConcept.new(
                          coding: [
                            FHIR::Coding.new(
                              system: 'https://codesystem.x12.org/005010/306',
                              code: 'A1',
                              display: 'Certified in total'
                            )
                          ]
                        )
                      )
                    ]
                  )
                ],
                category: FHIR::CodeableConcept.new(
                  coding: [
                    FHIR::Coding.new(system: 'http://terminology.hl7.org/CodeSystem/adjudication', code: 'submitted')
                  ]
                )
              )
            ]
          )
        end
      )
    end

    def handle_missing_required_elements(claim_entry, response)
      response.status = 400
      details = if claim_entry.blank?
                  'Required Claim entry missing from bundle'
                else
                  'Required element fullUrl missing from Claim entry'
                end
      response.body = FHIR::OperationOutcome.new(
        issue: FHIR::OperationOutcome::Issue.new(severity: 'fatal', code: 'required',
                                                 details: FHIR::CodeableConcept.new(text: details))
      ).to_json
    end

    def operation
      request.url&.split('$')&.last
    end

    # Drop the last two segments of a URL, i.e. the resource type and ID of a FHIR resource
    # e.g. http://example.org/fhir/Patient/123 -> http://example.org/fhir
    # @private
    def base_url(url)
      return unless url&.start_with?('http://', 'https://')

      # Drop everything after the second to last '/', ignoring a trailing slash
      url.sub(%r{/[^/]*/[^/]*(/)?\z}, '')
    end

    def referenced_entities(resource, entries, root_url)
      matches = []
      attributes = resource&.source_hash&.keys
      attributes.each do |attr|
        value = resource.send(attr.to_sym)
        if value.is_a?(FHIR::Reference) && value.reference.present?
          match = find_matching_entry(value.reference, entries, root_url)
          if match.present? && matches.none?(match)
            value.reference = match.fullUrl
            matches.concat([match], referenced_entities(match.resource, entries, root_url))
          end
        elsif value.is_a?(Array) && value.all? { |elmt| elmt.is_a?(FHIR::Model) }
          value.each { |val| matches.concat(referenced_entities(val, entries, root_url)) }
        end
      end

      matches
    end

    def absolute_reference(ref, entries, root_url)
      url = find_matching_entry(ref&.reference, entries, root_url)&.fullUrl
      ref.reference = url if url
      ref
    end

    def find_matching_entry(ref, entries, root_url = '')
      ref = "#{root_url}/#{ref}" if relative_reference?(ref) && root_url&.present?

      entries&.find { |entry| entry&.fullUrl == ref }
    end

    def relative_reference?(ref)
      ref&.count('/') == 1
    end
  end
end
