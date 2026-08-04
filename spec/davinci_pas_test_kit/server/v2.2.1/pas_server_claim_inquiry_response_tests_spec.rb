RSpec.describe DaVinciPASTestKit::DaVinciPASV221::ServerClaimInquiryResponseValidation, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v221' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:inquire_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::INQUIRE_PATH}" }

  def claim_response_bundle(request: nil, id: 'claim-inquiry-response')
    claim_response = {
      resourceType: 'ClaimResponse',
      id:,
      status: 'active',
      use: 'preauthorization',
      outcome: 'complete'
    }
    claim_response[:request] = request unless request.nil?

    {
      resourceType: 'Bundle',
      type: 'collection',
      entry: [{ resource: claim_response }]
    }
  end

  def parameters_response(bundle)
    {
      resourceType: 'Parameters',
      parameter: [
        {
          name: 'return',
          resource: bundle
        }
      ]
    }.to_json
  end

  def seed_inquire_response(response_body)
    repo_create(
      :request,
      direction: 'outgoing',
      url: inquire_url,
      test_session_id: test_session.id,
      result:,
      request_body: '{}',
      response_body:,
      tags: [DaVinciPASTestKit::INQUIRE_TAG, DaVinciPASTestKit::MUST_SUPPORT_WORKFLOW_TAG],
      status: 200
    )
  end

  describe DaVinciPASTestKit::DaVinciPASV221::PASServerClaimInquiryResponseClaimReferenceTest do # spec-44
    it 'skips when no Claim Inquiry Response ClaimResponse resources were returned' do
      seed_inquire_response(parameters_response({ resourceType: 'Bundle', type: 'collection', entry: [] }))

      expect(run(described_class).result).to eq('skip')
    end

    it 'skips when Bundles contain entries but no resources' do
      seed_inquire_response(parameters_response({ resourceType: 'Bundle', type: 'collection', entry: [{}] }))

      expect(run(described_class).result).to eq('skip')
    end

    it 'passes when the ClaimResponse request references a Claim' do
      bundle = claim_response_bundle(request: { reference: 'Claim/original-claim' })
      seed_inquire_response(parameters_response(bundle))

      expect(run(described_class).result).to eq('pass')
    end

    it 'passes when the ClaimResponse request has a Data Absent Reason extension' do
      bundle = claim_response_bundle(
        request: {
          extension: [
            {
              url: DaVinciPASTestKit::PASConstants::DATA_ABSENT_REASON_EXTENSION_URL,
              valueCode: 'unknown'
            }
          ]
        }
      )
      seed_inquire_response(parameters_response(bundle))

      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when the ClaimResponse request has neither a Claim reference nor Data Absent Reason' do
      bundle = claim_response_bundle(request: {})
      seed_inquire_response(parameters_response(bundle))

      expect(run(described_class).result).to eq('fail')
    end
  end
end
