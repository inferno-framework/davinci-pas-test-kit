RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PasNoCustomExtensionsTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v221' }
  let(:runnable) { described_class }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }

  let(:patient_resource) do
    {
      resourceType: 'Claim',
      id: 'example-claim',
      extension: [
        {
          url: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-TransmissionIdentifiers',
          valueCode: '248152002'
        }
      ]
    }
  end

  let(:patient_resource_with_custom_extension) do
    {
      resourceType: 'Claim',
      id: 'example-claim-2',
      extension: [
        {
          url: 'http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-TransmissionIdentifiers-custom',
          valueCode: '248152002'
        }
      ]
    }
  end

  let(:claim_resource) do
    {
      resourceType: 'Claim',
      id: 'example-claim',
      status: 'active',
      use: 'preauthorization'
    }
  end

  def pas_request_bundle(patient:)
    {
      resourceType: 'Bundle',
      type: 'collection',
      entry: [
        { resource: claim_resource },
        { resource: patient }
      ]
    }
  end

  def create_submit_request(body:, tags:, status: 200)
    repo_create(
      :request,
      result:,
      request_body: body.to_json,
      tags:,
      status:
    )
  end

  it 'skips when no prior authorization submissions were received' do
    test_result = run(runnable)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('No requests were made in a previous test as expected')
  end

  it 'skips when successful submissions contain no FHIR Bundle' do
    create_submit_request(
      body: claim_resource,
      tags: [DaVinciPASTestKit::SUBMIT_TAG]
    )

    test_result = run(runnable)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('No PAS Request Bundles were found')
  end

  it 'skips when all prior authorization submissions were unsuccessful' do
    create_submit_request(
      body: pas_request_bundle(patient: patient_resource),
      tags: [DaVinciPASTestKit::SUBMIT_TAG],
      status: 500
    )

    test_result = run(runnable)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('All service requests were unsuccessful')
  end

  it 'passes when a single submission contains no custom extensions' do
    create_submit_request(
      body: pas_request_bundle(patient: patient_resource),
      tags: [DaVinciPASTestKit::SUBMIT_TAG]
    )
    create_submit_request(
      body: pas_request_bundle(patient: patient_resource_with_custom_extension),
      tags: [DaVinciPASTestKit::SUBMIT_TAG]
    )

    test_result = run(runnable)

    expect(test_result.result).to eq('pass')
  end

  it 'skips if every submission contains custom extensions' do
    create_submit_request(
      body: pas_request_bundle(patient: patient_resource_with_custom_extension),
      tags: [DaVinciPASTestKit::SUBMIT_TAG]
    )

    test_result = run(runnable)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message)
      .to include('http://hl7.org/fhir/us/davinci-pas/StructureDefinition/extension-TransmissionIdentifiers-custom')
  end
end
