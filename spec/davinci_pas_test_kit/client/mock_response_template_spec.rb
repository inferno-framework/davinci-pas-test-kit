require 'active_support/testing/time_helpers'
require_relative '../../../lib/davinci_pas_test_kit/client/response_generator'
require_relative '../../../lib/davinci_pas_test_kit/cross_suite/fhirpath_utils'

# Checks that the responses Inferno mocks can be specified as tester-provided response templates: each template
# in spec/fixtures/response_templates, instantiated against a request and updated as Inferno updates tester-provided
# responses, must match the mocked response for that request.
#
# FHIRPath results come from spec/fixtures/response_templates/fhirpath_recordings.json, recorded from the FHIRPath
# service. To re-record after changing a template or request fixture, run the FHIRPath service and then run this
# spec with FHIRPATH_RECORD_URL set to the service's URL, e.g., http://localhost:6789.
module MockResponseTemplates
  FIXTURES_DIR = File.join(__dir__, '../../fixtures')
  TEMPLATES_DIR = File.join(FIXTURES_DIR, 'response_templates')
  RECORDINGS_PATH = File.join(TEMPLATES_DIR, 'fhirpath_recordings.json')
  SUBMIT_REQUESTS = %w[conformant_pas_bundle_v110 conformant_pas_bundle_v110_multiple_items
                       conformant_pas_bundle_v110_uuid].freeze
  INQUIRE_REQUESTS = %w[conformant_pas_inquire_bundle_v110].freeze

  def self.record_url
    ENV.fetch('FHIRPATH_RECORD_URL', nil)
  end

  def self.recordings
    @recordings ||=
      if record_url
        { 'recorded_on' => Date.today.iso8601, 'requests' => {} }
      else
        JSON.parse(File.read(RECORDINGS_PATH))
      end
  end
end

RSpec.describe 'Mocked responses as response templates' do # rubocop:disable RSpec/DescribeClass
  include ActiveSupport::Testing::TimeHelpers

  let(:generator) do
    url = MockResponseTemplates.record_url
    Class.new do
      include DaVinciPASTestKit::ResponseGenerator
      include DaVinciPASTestKit::FhirpathUtils

      attr_accessor :recorded

      public :update_tester_provided_response

      define_method(:fhirpath_evaluator) do
        @fhirpath_evaluator ||= Inferno::DSL::FhirpathEvaluation::Evaluator.new(url)
      end

      define_method(:execute_fhirpath) do |body, query|
        super(body, query).tap { |result| recorded[query] = JSON.parse(result.body) if url }
      end
    end.new
  end

  before do
    travel_to(Time.utc(*MockResponseTemplates.recordings['recorded_on'].split('-').map(&:to_i), 12))
  end

  # TimeHelpers only travels back automatically under Minitest
  after { travel_back }

  after(:context) do # rubocop:disable RSpec/BeforeAfterAll
    if MockResponseTemplates.record_url
      recordings = MockResponseTemplates.recordings
      recordings['requests'] = recordings['requests'].sort.to_h.transform_values { |results| results.sort.to_h }
      File.write(MockResponseTemplates::RECORDINGS_PATH, "#{JSON.pretty_generate(recordings)}\n")
    end
  end

  # Replays the recorded FHIRPath results for a request, or records them from the live service
  def use_fhirpath_results(request_name)
    recorded = MockResponseTemplates.recordings['requests'][request_name] ||= {}
    generator.recorded = recorded
    return WebMock.allow_net_connect! if MockResponseTemplates.record_url

    stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate").with(query: hash_including({})).to_return do |req|
      expression = CGI.parse(req.uri.query)['path'].first
      raise "No recorded FHIRPath results for '#{expression}' - see the comment at the top of this spec" unless
        recorded.key?(expression)

      { status: 200, body: recorded[expression].to_json }
    end
  end

  # Leaves out the random ids that the mock generates and the template fixes, and decodes narratives, which
  # the FHIRPath service returns with equivalent XHTML (e.g., `"` for `&quot;`).
  def normalize(response)
    bundle = response['resourceType'] == 'Parameters' ? response['parameter'][0]['resource'] : response
    bundle.delete('id')
    bundle['identifier']&.delete('value')
    bundle['entry'].each do |entry|
      text = entry['resource']['text']
      text['div'] = CGI.unescapeHTML(text['div']) if text.present?
    end
    response
  end

  {
    'submit_approval_v2.0.1' => ['submit', :approval, 'v2.0.1', MockResponseTemplates::SUBMIT_REQUESTS],
    'submit_denial_v2.0.1' => ['submit', :denial, 'v2.0.1', MockResponseTemplates::SUBMIT_REQUESTS],
    'submit_pended_v2.0.1' => ['submit', :pended, 'v2.0.1', MockResponseTemplates::SUBMIT_REQUESTS],
    'submit_modification_v2.0.1' => ['submit', :modification, 'v2.0.1', MockResponseTemplates::SUBMIT_REQUESTS],
    'submit_pended_v2.2.1' => ['submit', :pended, 'v2.2.1', MockResponseTemplates::SUBMIT_REQUESTS],
    'submit_modification_v2.2.1' => ['submit', :modification, 'v2.2.1', MockResponseTemplates::SUBMIT_REQUESTS],
    'inquire_approval_v2.0.1' => ['inquire', :approval, 'v2.0.1', MockResponseTemplates::INQUIRE_REQUESTS],
    'inquire_approval_v2.2.1' => ['inquire', :approval, 'v2.2.1', MockResponseTemplates::INQUIRE_REQUESTS]
  }.each do |template_name, (operation, decision, ig_version, request_names)|
    request_names.each do |request_name|
      it "reproduces the #{template_name} mock for #{request_name}" do
        template = JSON.parse(File.read(File.join(MockResponseTemplates::TEMPLATES_DIR, "#{template_name}.json")))
        request = FHIR.from_contents(File.read(File.join(MockResponseTemplates::FIXTURES_DIR, "#{request_name}.json")))
        claim_full_url = request.entry.find { |entry| entry.resource.resourceType == 'Claim' }.fullUrl
        use_fhirpath_results(request_name)

        instantiated = FHIR.from_contents(generator.instantiate_template(template, request).to_json).to_json
        templated = generator.update_tester_provided_response(instantiated, claim_full_url, operation, ig_version)
        mocked = generator.mock_response_bundle(request, operation, decision, template['entry'][0]['resource']['id'],
                                                ig_version)

        expect(normalize(JSON.parse(templated))).to eq(normalize(JSON.parse(mocked)))
      end
    end
  end
end
