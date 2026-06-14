# Behavioral specs for the PAS v2.2.1 Claim Update verification tests (ID-56). These exercise the
# FHIR-navigation logic in DaVinciPASV221::ClaimUpdateValidationUtils and each spec-65..72 test by
# seeding tagged Claim Update request Bundles and running the tests against them. No FHIR validator
# is involved - the verification tests are pure structural checks.
RSpec.describe DaVinciPASTestKit::DaVinciPASV221::ClaimUpdateValidationUtils, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  cert_url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-certificationType'
  info_changed_url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-infoChanged'
  info_cancelled_url = 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/modifierextension-infoCancelled'
  x12_system = 'https://codesystem.x12.org/005010/1322'

  urn1 = 'urn:uuid:11111111-1111-4111-8111-111111111111'
  urn2 = 'urn:uuid:22222222-2222-4222-8222-222222222222'
  urn3 = 'urn:uuid:33333333-3333-4333-8333-333333333333'
  urn4 = 'urn:uuid:44444444-4444-4444-8444-444444444444'

  define_method(:cancel_extension) do
    { url: cert_url, valueCodeableConcept: { coding: [{ system: x12_system, code: '3' }] } }
  end

  define_method(:build_item) do |seq, info_changed: nil, cancel: false, serviced: nil, certification_only: false|
    item = { sequence: seq, productOrService: { text: "service-#{seq}" } }
    item[:servicedDate] = serviced if serviced
    extensions = []
    extensions << { url: info_changed_url, valueCode: info_changed } if info_changed
    extensions << cancel_extension if cancel || certification_only
    item[:extension] = extensions unless extensions.empty?
    item[:modifierExtension] = [{ url: info_cancelled_url, valueBoolean: true }] if cancel
    item
  end

  define_method(:build_claim) do |id, related_ref: nil, items: [], cancel_all: false, provider_ref: nil|
    claim = { resourceType: 'Claim', id:, status: 'active', use: 'preauthorization' }
    claim[:related] = [{ claim: { reference: related_ref } }] if related_ref
    claim[:provider] = { reference: provider_ref } if provider_ref
    claim[:item] = items unless items.empty?
    claim[:extension] = [cancel_extension] if cancel_all
    claim
  end

  define_method(:bundle_json) do |*entries|
    { resourceType: 'Bundle', type: 'collection', entry: entries }.to_json
  end

  define_method(:entry) do |full_url, resource|
    { fullUrl: full_url, resource: }
  end

  define_method(:seed_request) do |tag, body|
    repo_create(
      :request,
      direction: 'incoming',
      url: "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}",
      test_session_id: test_session.id,
      result:,
      request_body: body,
      tags: [tag, DaVinciPASTestKit::SUBMIT_TAG],
      status: 200
    )
  end

  # Conformant reusable Claim resources.
  define_method(:claim1) { build_claim('claim-1', items: [build_item(1)]) }
  define_method(:claim2) do
    build_claim('claim-2', related_ref: urn1, items: [build_item(1), build_item(2, info_changed: 'added')])
  end
  define_method(:claim3) do
    build_claim('claim-3', related_ref: urn2,
                           items: [build_item(1, info_changed: 'changed', serviced: '2026-02-02'),
                                   build_item(2, cancel: true, info_changed: 'changed')])
  end
  define_method(:claim4) { build_claim('claim-4', related_ref: urn3, cancel_all: true) }

  # Seeds a fully conformant initial submission + three updates.
  define_method(:seed_conformant_sequence) do
    seed_request(DaVinciPASTestKit::CLAIM_UPDATE_INITIAL_TAG, bundle_json(entry(urn1, claim1)))
    seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, bundle_json(entry(urn2, claim2), entry(urn1, claim1)))
    seed_request(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                 bundle_json(entry(urn3, claim3), entry(urn2, claim2)))
    seed_request(DaVinciPASTestKit::CLAIM_UPDATE_CANCEL_ALL_TAG,
                 bundle_json(entry(urn4, claim4), entry(urn3, claim3)))
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateReferencedClaimTest do # spec-65
    it 'skips when no claim update requests were received' do
      expect(run(described_class).result).to eq('skip')
    end

    it 'passes when each update references and includes the updated Claim' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when the referenced Claim is not included in the Bundle' do
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, bundle_json(entry(urn2, claim2)))
      result = run(described_class)
      expect(result.result).to eq('fail')
    end

    it 'fails when an update has no Claim.related.claim' do
      no_related = build_claim('claim-2', items: [build_item(1)])
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, bundle_json(entry(urn2, no_related)))
      expect(run(described_class).result).to eq('fail')
    end
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateGrandparentExcludedTest do # spec-66
    it 'skips when no update references another update' do
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, bundle_json(entry(urn2, claim2), entry(urn1, claim1)))
      expect(run(described_class).result).to eq('skip')
    end

    it 'passes when the grandparent Claim is omitted' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when the grandparent Claim is included' do
      # claim3 references claim2 (itself an update referencing claim1); including claim1 violates spec-66.
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                   bundle_json(entry(urn3, claim3), entry(urn2, claim2), entry(urn1, claim1)))
      expect(run(described_class).result).to eq('fail')
    end
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateReferencedResourcesTest do # spec-67
    it 'passes when all other referenced resources are present' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when a referenced resource (other than the related Claim) is missing' do
      claim_missing_provider = build_claim('claim-2', related_ref: urn1, items: [build_item(1)],
                                                      provider_ref: 'urn:uuid:99999999-9999-4999-8999-999999999999')
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG,
                   bundle_json(entry(urn2, claim_missing_provider), entry(urn1, claim1)))
      expect(run(described_class).result).to eq('fail')
    end

    it 'does not flag the deliberately-omitted grandparent Claim' do
      # The modify-and-cancel bundle includes claim2 (an update referencing absent claim1); spec-67
      # must not treat that omission as a missing referenced resource.
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                   bundle_json(entry(urn3, claim3), entry(urn2, claim2)))
      expect(run(described_class).result).to eq('pass')
    end
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateEntriesPreservedTest do # spec-68
    it 'passes when all prior item sequences are preserved' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when a prior item sequence is dropped' do
      claim3_missing_item1 = build_claim('claim-3', related_ref: urn2,
                                                    items: [build_item(2, cancel: true, info_changed: 'changed')])
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, bundle_json(entry(urn2, claim2), entry(urn1, claim1)))
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                   bundle_json(entry(urn3, claim3_missing_item1), entry(urn2, claim2)))
      expect(run(described_class).result).to eq('fail')
    end
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateCancelledEntriesTest do # spec-69
    it 'skips when no entries are canceled' do
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, bundle_json(entry(urn2, claim2), entry(urn1, claim1)))
      expect(run(described_class).result).to eq('skip')
    end

    it 'passes when canceled items carry infoCancelled true' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when a canceled item is missing the infoCancelled modifier extension' do
      # certificationType Cancel present but no infoCancelled modifier extension.
      cancelled_item = build_item(2, info_changed: 'changed', certification_only: true)
      claim3_bad = build_claim('claim-3', related_ref: urn2,
                                          items: [build_item(1, info_changed: 'changed'), cancelled_item])
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                   bundle_json(entry(urn3, claim3_bad), entry(urn2, claim2)))
      expect(run(described_class).result).to eq('fail')
    end
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateCancelledItemsCertificationTypeTest do # spec-70
    it 'passes when canceled items carry a certificationType Cancel extension' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when a canceled item lacks the certificationType Cancel extension' do
      cancelled_no_cert = { sequence: 2, productOrService: { text: 'service-2' },
                            extension: [{ url: info_changed_url, valueCode: 'changed' }],
                            modifierExtension: [{ url: info_cancelled_url, valueBoolean: true }] }
      claim3_bad = build_claim('claim-3', related_ref: urn2,
                                          items: [build_item(1, info_changed: 'changed'), cancelled_no_cert])
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                   bundle_json(entry(urn3, claim3_bad), entry(urn2, claim2)))
      expect(run(described_class).result).to eq('fail')
    end
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateChangedEntriesTest do # spec-71
    it 'passes when added, modified, and canceled entries are all marked with infoChanged' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when an added item is not marked with infoChanged' do
      claim2_unmarked = build_claim('claim-2', related_ref: urn1, items: [build_item(1), build_item(2)])
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_INITIAL_TAG, bundle_json(entry(urn1, claim1)))
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG,
                   bundle_json(entry(urn2, claim2_unmarked), entry(urn1, claim1)))
      expect(run(described_class).result).to eq('fail')
    end

    it 'fails when a modified item is not marked with infoChanged' do
      claim3_unmarked = build_claim('claim-3', related_ref: urn2,
                                               items: [build_item(1, serviced: '2026-02-02'),
                                                       build_item(2, cancel: true, info_changed: 'changed')])
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG, bundle_json(entry(urn2, claim2), entry(urn1, claim1)))
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_MODIFY_CANCEL_TAG,
                   bundle_json(entry(urn3, claim3_unmarked), entry(urn2, claim2)))
      expect(run(described_class).result).to eq('fail')
    end
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASClientClaimUpdateInfoChangedCodeTest do # spec-72
    it 'passes when infoChanged valueCodes match the value set semantics' do
      seed_conformant_sequence
      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when an added entry uses valueCode changed instead of added' do
      claim2_wrong_code = build_claim('claim-2', related_ref: urn1,
                                                 items: [build_item(1), build_item(2, info_changed: 'changed')])
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_INITIAL_TAG, bundle_json(entry(urn1, claim1)))
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG,
                   bundle_json(entry(urn2, claim2_wrong_code), entry(urn1, claim1)))
      expect(run(described_class).result).to eq('fail')
    end

    it 'fails when an infoChanged valueCode is not in the value set' do
      claim2_bad_code = build_claim('claim-2', related_ref: urn1,
                                               items: [build_item(1), build_item(2, info_changed: 'bogus')])
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_INITIAL_TAG, bundle_json(entry(urn1, claim1)))
      seed_request(DaVinciPASTestKit::CLAIM_UPDATE_ADD_ITEM_TAG,
                   bundle_json(entry(urn2, claim2_bad_code), entry(urn1, claim1)))
      expect(run(described_class).result).to eq('fail')
    end
  end
end
