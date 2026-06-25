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

  # require_one_of with the full set of submit request profiles, as the real submit group configures it.
  let(:multi_request_profiles_test) do
    Class.new(described_class) do
      config(
        options: {
          profiles: [
            { resource_type: 'DeviceRequest', profile_key: 'device_request', title: 'PAS Device Request' },
            { resource_type: 'MedicationRequest', profile_key: 'medication_request', title: 'PAS Medication Request' },
            { resource_type: 'NutritionOrder', profile_key: 'nutrition_order', title: 'PAS Nutrition Order' },
            { resource_type: 'ServiceRequest', profile_key: 'service_request', title: 'PAS Service Request' }
          ],
          require_one_of: true,
          ig_version: 'v2.2.1',
          type: 'request',
          operation: 'submit'
        }
      )
    end
  end

  # Two profiles that share a single resource type (Organization), as in the real submit group.
  let(:shared_org_test) do
    Class.new(described_class) do
      config(
        options: {
          profiles: [
            { resource_type: 'Organization', profile_key: 'insurer', title: 'PAS Insurer Organization' },
            { resource_type: 'Organization', profile_key: 'requestor', title: 'PAS Requestor Organization' }
          ],
          require_one_of: false,
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

  # A DeviceRequest present but missing several must support elements (code[x], coverage, occurrence[x]).
  def incomplete_device_request_bundle
    device_request = FHIR::DeviceRequest.new(status: 'active', intent: 'order', subject: { reference: 'Patient/1' })
    FHIR::Bundle.new(type: 'collection', entry: [{ resource: device_request }]).to_json
  end

  # A ServiceRequest present but missing several must support elements.
  def incomplete_service_request_bundle
    service_request = FHIR::ServiceRequest.new(status: 'active', intent: 'order', subject: { reference: 'Patient/1' })
    FHIR::Bundle.new(type: 'collection', entry: [{ resource: service_request }]).to_json
  end

  # A bare Organization (shared resource type for the Insurer and Requestor profiles).
  def minimal_organization_bundle
    organization = FHIR::Organization.new(active: true, name: 'Test Organization')
    FHIR::Bundle.new(type: 'collection', entry: [{ resource: organization }]).to_json
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

  describe 'when require_one_of is false and no matching resources are in the session' do
    it 'does not silently pass; flags the resource type as unobserved and waits for attestation' do
      # A request is sent, but it contains no Coverage resource at all.
      create_submit_request(FHIR::Bundle.new(type: 'collection').to_json)

      result = run(coverage_test)
      expect(result.result).to eq('wait')
      expect(result.result_message).to match(/no Coverage instances were observed/)
    end
  end

  describe 'when require_one_of is true and a present profile is missing must support elements' do
    it 'assesses the present profile (does not skip it) and waits for attestation' do
      create_submit_request(incomplete_device_request_bundle)

      # Present -> not a hard fail; missing elements -> not a pass, so it must wait for attestation.
      result = run(require_one_of_test)
      expect(result.result).to eq('wait')
      expect(result.result_message).to match(/PAS Device Request/)
    end
  end

  describe 'when require_one_of is true with multiple profiles and only some are present' do
    it 'assesses the present profile and skips the absent ones' do
      # Only a (incomplete) ServiceRequest is present; Device/Medication/Nutrition are absent.
      create_submit_request(incomplete_service_request_bundle)

      result = run(multi_request_profiles_test)
      expect(result.result).to eq('wait')

      message = result.result_message
      expect(message).to match(/PAS Service Request/)     # present -> assessed
      expect(message).to_not match(/PAS Device Request/)  # absent -> skipped (not flagged)
      expect(message).to_not match(/PAS Medication Request/)
      expect(message).to_not match(/PAS Nutrition Order/)
    end
  end

  describe 'when multiple profiles share a single resource type (Organization)' do
    it 'assesses each profile against the shared resource pool' do
      create_submit_request(minimal_organization_bundle)

      result = run(shared_org_test)
      expect(result.result).to eq('wait')

      message = result.result_message
      expect(message).to match(/PAS Insurer Organization/)
      expect(message).to match(/PAS Requestor Organization/)
    end
  end

  describe 'when no requests have been submitted at all (empty session)' do
    it 'hard-fails a require_one_of test' do
      result = run(require_one_of_test)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/must include at least one/)
    end

    it 'does not silently pass a require_one_of: false test' do
      result = run(coverage_test)
      expect(result.result).to_not eq('pass')
    end
  end

  describe 'the attestation wait message' do
    it 'lists the unobserved elements by profile and includes the pass/fail attestation links' do
      create_submit_request(incomplete_coverage_bundle)

      result = run(coverage_test)
      expect(result.result).to eq('wait')

      message = result.result_message
      expect(message).to match(/- PAS Coverage: .+/) # profile name + at least one element listed
      expect(message).to include('The test will **pass**')
      expect(message).to include('The test will **fail**')
      expect(message).to match(/\[Click here\]\(http.*\)/) # markdown attestation links
    end
  end

  describe '.build_description (load-time description from metadata)' do
    it 'lists each configured profile with its must support elements' do
      options = {
        profiles: [{ resource_type: 'Coverage', profile_key: 'coverage', title: 'PAS Coverage' }],
        require_one_of: false, ig_version: 'v2.2.1', type: 'request', operation: 'submit'
      }

      description = described_class.build_description(options)
      expect(description).to include('### PAS Coverage')
      expect(description).to match(/^\* Coverage\./) # at least one must support element listed
      expect(description).to match(/must support elements/) # intro text
    end

    it 'uses the "at least one" intro when require_one_of is true' do
      options = {
        profiles: [{ resource_type: 'DeviceRequest', profile_key: 'device_request', title: 'PAS Device Request' }],
        require_one_of: true, ig_version: 'v2.2.1', type: 'request', operation: 'submit'
      }

      description = described_class.build_description(options)
      expect(description).to match(/must support at least one of them/)
      expect(description).to include('### PAS Device Request')
    end
  end

  describe 'the generated submit request-profiles attestation test' do
    it 'has a description built from the metadata at load time' do
      group = DaVinciPASTestKit::DaVinciPASV221::PASClientSubmitMustSupportGroup
      test = group.tests.find do |child|
        child.id.to_s.end_with?('submit_request_profiles_must_support_with_attestation_option')
      end

      expect(test).to_not be_nil
      expect(test.description).to include('### PAS Device Request')
      expect(test.description).to match(/\* DeviceRequest\./)
    end
  end
end
