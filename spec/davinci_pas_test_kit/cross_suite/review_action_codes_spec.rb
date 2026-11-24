require_relative '../../../lib/davinci_pas_test_kit/cross_suite/review_action_codes'

RSpec.describe DaVinciPASTestKit::ReviewActionCodes do
  def adjudication(*codes)
    review_actions = codes.map do |code|
      { 'url' => DaVinciPASTestKit::PASConstants::REVIEW_ACTION_EXTENSION_URL,
        'extension' => [{ 'url' => DaVinciPASTestKit::PASConstants::REVIEW_ACTION_CODE_EXTENSION_URL,
                          'valueCodeableConcept' => { 'coding' => [{ 'code' => code }] } }] }
    end
    { 'extension' => review_actions }
  end

  it 'reads the review action codes on an adjudication' do
    expect(described_class.codes(adjudication('A1', 'A4'))).to eq(%w[A1 A4])
  end

  it 'ignores extensions other than the review action' do
    item = { 'adjudication' => [{ 'extension' => [{ 'url' => 'urn:other', 'valueString' => 'A4' }] }] }

    expect(described_class.item_has_code?(item, 'A4')).to be(false)
  end

  it 'finds a code on any item of a ClaimResponse' do
    claim_response = { 'item' => [{ 'adjudication' => [adjudication('A1')] },
                                  { 'adjudication' => [adjudication('A6')] }] }

    expect(described_class.claim_response_has_code?(claim_response, 'A6')).to be(true)
    expect(described_class.claim_response_has_code?(claim_response, 'A4')).to be(false)
  end

  it 'reads FHIR models through their hash' do
    item = FHIR::ClaimResponse::Item.new('adjudication' => [adjudication('A6')])

    expect(described_class.item_has_code?(item.to_hash, 'A6')).to be(true)
  end

  it 'ignores malformed values' do
    claim_response = { 'item' => [5, { 'adjudication' => 'x' }, { 'adjudication' => [{ 'extension' => { 'a' => 1 } }] },
                                  { 'adjudication' => [adjudication('A4')] }] }

    expect(described_class.claim_response_has_code?(claim_response, 'A4')).to be(true)
    expect(described_class.claim_response_has_code?(nil, 'A4')).to be(false)
    expect(described_class.codes('x')).to eq([])
  end
end
