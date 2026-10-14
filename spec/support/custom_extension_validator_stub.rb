# Stubs the FHIR resource validator so that specs can exercise how tests react to custom extensions
# without a running validator service:
# - the strict :no_custom_extensions validator (sent `extensions: []`) reports the HL7 validator's
#   unknown extension error for each extension, at any depth, whose url is in unknown_extension_urls.
# - the :default validator (sent `extensions: ['any']`) allows them.
# Everything else is valid. Reference-following FHIRPath lookups return nothing.
RSpec.shared_context 'with custom extension validator stub' do
  let(:custom_extension_url) { 'urn:inferno-custom' }
  let(:custom_extension) { { 'url' => custom_extension_url, 'valueString' => 'x' } }
  # Extensions the strict validator can't resolve, i.e., not defined in the IGs it loads.
  let(:unknown_extension_urls) { [custom_extension_url] }

  # [location, url] pairs for each extension in the value, with validator-style locations, e.g.,
  # `Claim.identifier[0].extension[1]` or, for a primitive's extension held in `_birthDate`,
  # `Patient.birthDate.extension[0]`.
  def stubbed_extension_locations(value, path)
    case value
    when Hash
      value.flat_map do |key, child|
        child_path = "#{path}.#{key.delete_prefix('_')}"
        if %w[extension modifierExtension].include?(key) && child.is_a?(Array)
          child.each_with_index.flat_map do |extension, index|
            [["#{child_path}[#{index}]", extension['url']]] +
              stubbed_extension_locations(extension, "#{child_path}[#{index}]")
          end
        else
          stubbed_extension_locations(child, child_path)
        end
      end
    when Array
      value.each_with_index.flat_map { |child, index| stubbed_extension_locations(child, "#{path}[#{index}]") }
    else
      []
    end
  end

  def stubbed_validator_issues(resource, context)
    return [] unless context['extensions'] == []

    resource_hash = resource.except('resourceType')
    stubbed_extension_locations(resource_hash, resource['resourceType']).filter_map do |location, url|
      next unless unknown_extension_urls.include?(url)

      { level: 'ERROR', location:, message: "The extension #{url} could not be found so is not allowed here" }
    end
  end

  before do
    stub_request(:post, %r{/fhirpath/evaluate}).to_return(status: 200, body: '[]')
    stub_request(:post, validation_url).to_return do |request|
      body = JSON.parse(request.body)
      context = body['validationContext'] || body['cliContext']
      resource = JSON.parse(body['filesToValidate'].first['fileContent'])
      # No sessionId: specs using both validators would otherwise save the same validator session twice.
      { status: 200, body: { outcomes: [{ issues: stubbed_validator_issues(resource, context) }] }.to_json }
    end
  end
end
