RSpec.describe DaVinciPASTestKit::PASSubscriptionNotificationWaitTest, :request do
  let(:suite_id) { 'davinci_pas_server_suite_v201' }

  let(:access_token) { '1234' }
  let(:test) { described_class }
  let(:resume_skip_url) { "/custom/#{suite_id}/resume_skip" }
  let(:notification_url) { '/custom/subscriptions_r5_backport_r4_server/subscription/channel/notification_listener' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:notification_body) do
    File.read(File.join(__dir__, '../..', 'fixtures', 'PAS_notification_example_id_only.json'))
  end

  it 'passes when a notification is received' do
    result = run(test, access_token:)
    expect(result.result).to eq('wait')

    header('Authorization', "Bearer #{access_token}")
    post notification_url, notification_body, 'CONTENT_TYPE' => 'application/fhir+json'

    result = results_repo.find(result.id)
    expect(result.result).to eq('pass')
  end

  it 'skips when the tester chooses to skip the tests' do
    result = run(test, access_token:)
    expect(result.result).to eq('wait')

    get("#{resume_skip_url}?token=notification+#{access_token}")

    result = results_repo.find(result.id)
    expect(result.result).to eq('skip')
  end
end
