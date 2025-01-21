require 'spec_helper'
require 'rack/test'
require 'inferno/apps/web/application'
require 'fhir_models'

module RequestHelpers
  def app
    Inferno::Web.app
  end

  def post_fhir(path, data)
    post path, data.to_json, 'CONTENT_TYPE' => 'application/fhir+json'
  end

  def fhir_body
    FHIR.from_contents(last_response.body)
  end

  def parsed_body
    JSON.parse(last_response.body)
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/routes/}) do |metadata|
    metadata[:request] = true
  end

  config.include Rack::Test::Methods, request: true
  config.include RequestHelpers, request: true
end
