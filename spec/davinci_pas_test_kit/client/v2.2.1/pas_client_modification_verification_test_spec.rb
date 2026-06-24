RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PasClientModificationVerificationTest, :request do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:modification_response) do
    response_bundle(
      item: [{ 'itemSequence' => 1, 'adjudication' => [review_action_adjudication('A6')] }],
      add_item: [{
        'itemSequence' => [1],
        'productOrService' => { 'coding' => [{ 'system' => 'http://www.ama-assn.org/go/cpt', 'code' => '99213' }] },
        'adjudication' => [review_action_adjudication('A1')]
      }]
    )
  end
  let(:approval_only_response) do
    response_bundle(
      item: [{ 'itemSequence' => 1, 'adjudication' => [review_action_adjudication('A1')] }]
    )
  end
  let(:modification_without_add_item_response) do
    response_bundle(
      item: [{ 'itemSequence' => 1, 'adjudication' => [review_action_adjudication('A6')] }]
    )
  end
  let(:modification_tags) do
    [DaVinciPASTestKit::MODIFICATION_WORKFLOW_TAG, DaVinciPASTestKit::SUBMIT_TAG]
  end
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }

  def review_action_adjudication(code)
    {
      'extension' => [
        {
          'url' => 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewAction',
          'extension' => [
            {
              'url' => 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-reviewActionCode',
              'valueCodeableConcept' => {
                'coding' => [
                  { 'system' => 'https://codesystem.x12.org/005010/306', 'code' => code }
                ]
              }
            }
          ]
        }
      ],
      'category' => {
        'coding' => [
          { 'system' => 'http://terminology.hl7.org/CodeSystem/adjudication', 'code' => 'submitted' }
        ]
      }
    }
  end

  def response_bundle(item:, add_item: [])
    {
      'resourceType' => 'Bundle',
      'type' => 'collection',
      'entry' => [
        {
          'fullUrl' => 'urn:uuid:11111111-1111-1111-1111-111111111111',
          'resource' => {
            'resourceType' => 'ClaimResponse',
            'item' => item,
            'addItem' => add_item
          }
        }
      ]
    }.to_json
  end

  def create_submit_response(bundle_string, tags_list)
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      response_body: bundle_string,
      tags: tags_list,
      status: 200
    )
  end

  it 'skips when no submit requests were made' do
    result = run(described_class)
    expect(result.result).to eq('skip')
  end

  it 'passes when the response contains an A6 item and a matching addItem' do
    create_submit_response(modification_response, modification_tags)
    result = run(described_class)
    expect(result.result).to eq('pass')
  end

  it 'fails when no item carries the A6 modified review action code' do
    create_submit_response(approval_only_response, modification_tags)
    result = run(described_class)
    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/A6/)
  end

  it 'fails when a modified item has no matching addItem' do
    create_submit_response(modification_without_add_item_response, modification_tags)
    result = run(described_class)
    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/addItem/)
  end
end
