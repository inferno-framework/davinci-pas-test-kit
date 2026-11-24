require_relative '../../../lib/davinci_pas_test_kit/client/pended_response_detection'

RSpec.describe DaVinciPASTestKit::PendedResponseDetection do
  def review_action(code)
    { 'url' => DaVinciPASTestKit::PASConstants::REVIEW_ACTION_EXTENSION_URL,
      'extension' => [{ 'url' => DaVinciPASTestKit::PASConstants::REVIEW_ACTION_CODE_EXTENSION_URL,
                        'valueCodeableConcept' => { 'coding' => [{ 'code' => code }] } }] }
  end

  def response_bundle(*codes)
    items = codes.map { |code| { 'adjudication' => [{ 'extension' => [review_action(code)] }] } }
    { 'resourceType' => 'Bundle', 'type' => 'collection',
      'entry' => [{ 'resource' => { 'resourceType' => 'ClaimResponse', 'item' => items } }] }
  end

  it 'identifies a response with an item adjudication pended with review action code A4' do
    expect(described_class.pended?(response_bundle('A1', 'A4'))).to be(true)
  end

  it 'accepts the response as JSON' do
    expect(described_class.pended?(response_bundle('A4').to_json)).to be(true)
  end

  it 'does not identify a response without the pended review action code' do
    expect(described_class.pended?(response_bundle('A1', 'A3'))).to be(false)
  end

  it 'identifies the pended response in Inferno\'s mocked v2.2.1 responses' do
    generator = Class.new { include DaVinciPASTestKit::ResponseGenerator }.new
    request_bundle = FHIR.from_contents(
      File.read(File.join(__dir__, '../..', 'fixtures', 'conformant_pas_bundle_v110.json'))
    )

    pended = generator.mock_response_bundle(request_bundle, 'submit', :pended, nil, 'v2.2.1')
    approved = generator.mock_response_bundle(request_bundle, 'submit', :approval, nil, 'v2.2.1')

    expect(described_class.pended?(pended)).to be(true)
    expect(described_class.pended?(approved)).to be(false)
  end

  it 'treats content that is not a Bundle, or is malformed, as not pended' do
    malformed = { 'resourceType' => 'Bundle', 'entry' => [{ 'resource' => { 'resourceType' => 'ClaimResponse',
                                                                            'item' => 'not a list' } }, 'x'] }

    expect(described_class.pended?(malformed)).to be(false)
    expect(described_class.pended?({ 'resourceType' => 'Parameters' })).to be(false)
    expect(described_class.pended?('not json')).to be(false)
    expect(described_class.pended?(nil)).to be(false)
  end

  it 'ignores malformed elements while still finding a pended item' do
    bundle = response_bundle('A4')
    claim_response = bundle['entry'].first['resource']
    claim_response['item'] = [{ 'adjudication' => 5 }, { 'adjudication' => [{ 'extension' => { 'url' => 'x' } }] },
                              { 'adjudication' => [{ 'extension' => [{ 'url' => 'x', 'extension' => 'y' }] }] },
                              *claim_response['item']]

    expect(described_class.pended?(bundle)).to be(true)
  end

  it 'does not treat a review action code whose coding is malformed as pended' do
    bundle = response_bundle('A4')
    bundle['entry'].first['resource']['item'].first['adjudication'].first['extension'].first['extension'].first[
      'valueCodeableConcept'
    ]['coding'] = 'A4'

    expect(described_class.pended?(bundle)).to be(false)
  end
end
