RSpec.describe DaVinciPASTestKit::DaVinciPASV221::PASServerSubscriptionCapabilityStatementTest, :runnable do
  let(:suite_id) { 'davinci_pas_server_suite_v221' }
  let(:server_endpoint) { 'http://example.com/fhir' }

  let(:test) do
    Class.new(described_class) do
      fhir_client { url :server_endpoint }

      input :server_endpoint
    end
  end

  before do
    allow_any_instance_of(test).to receive(:assert_valid_resource).and_return(true)
  end

  def capability_statement(
    interactions: ['create', 'update', 'delete'],
    subscription_resource: true,
    server_rest: true
  )
    resources = []

    if subscription_resource
      resources << {
        type: 'Subscription',
        interaction: interactions.map { |code| { code: } }
      }
    end

    rest = []

    if server_rest
      rest << {
        mode: 'server',
        resource: resources
      }
    end

    {
      resourceType: 'CapabilityStatement',
      status: 'active',
      kind: 'instance',
      date: '2026-01-01',
      implementation: {
        description: 'Example PAS server'
      },
      fhirVersion: '4.0.1',
      format: ['json'],
      rest:
    }.to_json
  end

  def stub_capability_statement(body)
    stub_request(:get, "#{server_endpoint}/metadata")
      .to_return(
        status: 200,
        body:,
        headers: { 'Content-Type' => 'application/fhir+json' }
      )
  end

  it 'passes when the server declares all required Subscription interactions' do
    stub_capability_statement(capability_statement)

    result = run(test, server_endpoint:)

    expect(result.result).to eq('pass')
  end

  it 'fails when the server does not declare a Subscription resource' do
    stub_capability_statement(
      capability_statement(subscription_resource: false)
    )

    result = run(test, server_endpoint:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'CapabilityStatement is missing a `Subscription` resource entry ' \
      'in its server-mode `rest` section.'
    )
  end

  it 'fails when the Subscription resource is missing a required interaction' do
    stub_capability_statement(
      capability_statement(interactions: ['create', 'update'])
    )

    result = run(test, server_endpoint:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'Missing interactions in the subscription: delete'
    )
  end

  it 'fails when the CapabilityStatement has no server-mode rest entry' do
    stub_capability_statement(
      capability_statement(server_rest: false)
    )

    result = run(test, server_endpoint:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'CapabilityStatement is missing a `rest` entry with `mode` set to `server`.'
    )
  end
end
