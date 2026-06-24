RSpec.describe DaVinciPASTestKit::DaVinciPASV221::MustSupportWithAttestationOption, :request, :runnable do
  let(:suite_id) { 'davinci_pas_client_suite_v221' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:submit_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::SUBMIT_PATH}" }
  # The attestation test waits on its test_session_id; the resume token must match it.
  let(:continue_pass_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_PASS_PATH}?token=#{test_session.id}" }
  let(:continue_fail_url) { "/custom/#{suite_id}#{DaVinciPASTestKit::RESUME_FAIL_PATH}?token=#{test_session.id}" }

  let(:coverage_test) do
    Class.new(described_class) do
      config(
        options: {
          profiles: [{ resource_type: 'Coverage', profile_key: 'coverage', title: 'PAS Coverage' }],
          require_one_of: false,
          ig_version: 'v2.2.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end

  let(:require_one_of_test) do
    Class.new(described_class) do
      config(
        options: {
          profiles: [
            { resource_type: 'DeviceRequest', profile_key: 'device_request', title: 'PAS Device Request' }
          ],
          require_one_of: true,
          ig_version: 'v2.2.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end

  # A PAS Coverage with all of its must support elements present. The X12Code slice is only satisfied when an
  # x12.org relationship coding is present.
  def coverage_bundle(relationship_codings: [])
    coverage = FHIR::Coverage.new(
      status: 'active',
      identifier: [
        { type: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/v2-0203', code: 'MB' }] },
          value: 'member-123' }
      ],
      type: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'HIP' }] },
      subscriber: { reference: 'Patient/1' },
      subscriberId: 'sub-123',
      beneficiary: { reference: 'Patient/1' },
      relationship: { coding: relationship_codings },
      period: { start: '2024-01-01', end: '2025-01-01' },
      payor: [{ reference: 'Organization/1' }],
      class: [
        { type: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/coverage-class', code: 'group' }] },
          value: 'group-1', name: 'Group One' },
        { type: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/coverage-class', code: 'plan' }] },
          value: 'plan-1', name: 'Plan One' }
      ]
    )

    FHIR::Bundle.new(type: 'collection', entry: [{ resource: coverage }]).to_json
  end

  # A PAS Coverage missing several must support elements (type, subscriber, subscriberId, period, class).
  def incomplete_coverage_bundle
    coverage = FHIR::Coverage.new(
      status: 'active',
      identifier: [
        { type: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/v2-0203', code: 'MB' }] },
          value: 'member-123' }
      ],
      beneficiary: { reference: 'Patient/1' },
      relationship: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/subscriber-relationship',
                                 code: 'self' }] },
      payor: [{ reference: 'Organization/1' }]
    )

    FHIR::Bundle.new(type: 'collection', entry: [{ resource: coverage }]).to_json
  end

  def create_submit_request(request_bundle_string)
    repo_create(
      :request,
      direction: 'incoming',
      url: submit_url,
      test_session_id: test_session.id,
      result:,
      request_body: request_bundle_string,
      response_body: '',
      tags: [DaVinciPASTestKit::SUBMIT_TAG],
      status: 201
    )
  end

  describe 'when every must support element is observed' do
    it 'passes without requiring an attestation' do
      codings = [
        { system: 'http://terminology.hl7.org/CodeSystem/subscriber-relationship', code: 'self' },
        { system: 'https://codesystem.x12.org/005010/1069', code: '18' }
      ]
      create_submit_request(coverage_bundle(relationship_codings: codings))

      result = run(coverage_test)
      expect(result.result).to eq('pass')
    end
  end

  describe 'when must support elements are not observed' do
    before do
      create_submit_request(incomplete_coverage_bundle)
    end

    it 'logs each unobserved element as an info message and waits for an attestation' do
      result = run(coverage_test)
      expect(result.result).to eq('wait')

      result_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
      info_messages = result_messages.select { |message| message.type == 'info' }.map(&:message)
      expect(info_messages).to include(
        a_string_matching(/Unobserved must support element for profile PAS Coverage: /)
      )
    end

    it 'passes when the tester attests true' do
      result = run(coverage_test)
      expect(result.result).to eq('wait')

      get continue_pass_url
      expect(results_repo.find(result.id).result).to eq('pass')
    end

    it 'fails when the tester attests false' do
      result = run(coverage_test)
      expect(result.result).to eq('wait')

      get continue_fail_url
      expect(results_repo.find(result.id).result).to eq('fail')
    end
  end

  describe 'when require_one_of is true and none of the listed profiles are present' do
    it 'fails' do
      create_submit_request(FHIR::Bundle.new(type: 'collection').to_json)

      result = run(require_one_of_test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/must include at least one/)
    end
  end
end
