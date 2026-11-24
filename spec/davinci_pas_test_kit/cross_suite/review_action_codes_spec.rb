require_relative '../../../lib/davinci_pas_test_kit/cross_suite/review_action_codes'

RSpec.describe DaVinciPASTestKit::ReviewActionCodes do
  def adjudication(*codes)
    review_actions = codes.map do |code|
      { url: DaVinciPASTestKit::PASConstants::REVIEW_ACTION_EXTENSION_URL,
        extension: [{ url: DaVinciPASTestKit::PASConstants::REVIEW_ACTION_CODE_EXTENSION_URL,
                      valueCodeableConcept: { coding: [{ code: }] } }] }
    end
    { extension: review_actions }
  end

  def claim_response(*items)
    FHIR::ClaimResponse.new(item: items)
  end

  it 'reads the review action codes on an adjudication' do
    item = FHIR::ClaimResponse::Item.new(adjudication: [adjudication('A1', 'A4')])

    expect(described_class.codes(item.adjudication.first)).to eq(%w[A1 A4])
  end

  it 'ignores extensions other than the review action' do
    item = FHIR::ClaimResponse::Item.new(adjudication: [{ extension: [{ url: 'urn:other', valueString: 'A4' }] }])

    expect(described_class.item_has_code?(item, 'A4')).to be(false)
  end

  it 'finds a code on any item of a ClaimResponse' do
    response = claim_response({ adjudication: [adjudication('A1')] }, { adjudication: [adjudication('A6')] })

    expect(described_class.claim_response_has_code?(response, 'A6')).to be(true)
    expect(described_class.claim_response_has_code?(response, 'A4')).to be(false)
  end

  it 'skips the nils fhir_models leaves for malformed elements' do
    response = FHIR.from_contents({ resourceType: 'ClaimResponse',
                                    item: [{ adjudication: [5] }, { adjudication: [adjudication('A4')] }] }.to_json)

    expect(described_class.claim_response_has_code?(response, 'A4')).to be(true)
    expect(described_class.claim_response_has_code?(nil, 'A4')).to be(false)
  end
end
