module DaVinciPASTestKit
  module ResponseGenerator
    def mock_response_bundle(request_bundle, operation, decision)
      claim_entry = request_bundle&.entry&.find { |e| e&.resource&.resourceType == 'Claim' }
      claim_full_url = claim_entry&.fullUrl
      return nil if claim_entry.blank? || claim_full_url.blank?

      root_url = extract_fhir_base_url(claim_full_url)
      mocked_claim_response = mock_claim_response(claim_entry.resource, request_bundle, root_url, operation, decision)
      mocked_response_bundle = mock_bundle(mocked_claim_response, request_bundle, root_url, operation)
      mocked_response_bundle.to_json
    end

    def update_tester_provided_response(user_inputted_response, claim_full_url)
      response_bundle = FHIR.from_contents(user_inputted_response)
      claim_response_entry = response_bundle&.entry&.find { |e| e&.resource&.resourceType == 'ClaimResponse' }
      if claim_response_entry.blank?
        # echo bad response without modification, other tests will catch problems
        user_inputted_response
      else
        now = Time.now.utc
        response_bundle.timestamp = now.iso8601
        claim_response_entry.resource.created = now.iso8601
        if claim_response_entry.resource.request.present? && claim_full_url.present?
          claim_response_entry.resource.request.reference = claim_full_url
        end
        response_bundle.to_json
      end
    end

    # Drop the last two segments of a URL, i.e. the resource type and ID of a FHIR resource
    # e.g. http://example.org/fhir/Patient/123 -> http://example.org/fhir
    # @private
    def extract_fhir_base_url(url)
      return unless url&.start_with?('http://', 'https://')

      # Drop everything after the second to last '/', ignoring a trailing slash
      url.sub(%r{/[^/]*/[^/]*(/)?\z}, '')
    end

    private

    # Note that references from the claim to other resources in the bundle need to be changed to absolute URLs
    # if they are relative, because the ClaimResponse's fullUrl is a urn:uuid
    #
    # @private
    def mock_claim_response(claim, request_bundle, root_url, operation, decision)
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
        patient: absolute_reference(claim.patient, request_bundle.entry, root_url),
        created: now.iso8601,
        insurer: absolute_reference(claim.insurer, request_bundle.entry, root_url),
        requestor: absolute_reference(claim.provider, request_bundle.entry, root_url),
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
                            get_review_action_code(decision)
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

    def mock_bundle(claim_response, request_bundle, root_url, operation)
      response_bundle = FHIR::Bundle.new(
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
      response_bundle.entry.concat(referenced_entities(claim_response, request_bundle.entry, root_url))
      response_bundle
    end

    def get_review_action_code(decision)
      case decision
      when :denial
        code = 'A3'
        display = 'Not Certified'
      when :pended
        code = 'A4'
        display = 'Pending'
      else # approval or no workflow
        code = 'A1'
        display = 'Certified in total'
      end
      FHIR::Coding.new(
        system: 'https://codesystem.x12.org/005010/306',
        code:,
        display:
      )
    end

    def absolute_reference(ref, entries, root_url)
      url = find_matching_entry(ref&.reference, entries, root_url)&.fullUrl
      ref.reference = url if url
      ref
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

    def find_matching_entry(ref, entries, root_url = '')
      ref = "#{root_url}/#{ref}" if relative_reference?(ref) && root_url&.present?

      entries&.find { |entry| entry&.fullUrl == ref }
    end

    def relative_reference?(ref)
      ref&.count('/') == 1
    end
  end
end
