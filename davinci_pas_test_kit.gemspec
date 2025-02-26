require_relative 'lib/davinci_pas_test_kit/version'

Gem::Specification.new do |spec|
  spec.name          = 'davinci_pas_test_kit'
  spec.version       = DaVinciPASTestKit::VERSION
  spec.authors       = ['Inferno Team']
  spec.email         = ['inferno@groups.mitre.org']
  spec.date          = Time.now.utc.strftime('%Y-%m-%d')
  spec.summary       = 'Da Vinci PAS Test Kit'
  spec.description   = 'Inferno Test Kit for the Da Vinci Prior Authorization Support IG'
  spec.homepage      = 'https://github.com/inferno-framework/davinci-pas-test-kit'
  spec.license       = 'Apache-2.0'
  spec.add_dependency 'inferno_core', '~> 0.6.2'
  spec.add_dependency 'subscriptions_test_kit', '~> 0.9.4'
  spec.add_development_dependency 'database_cleaner-sequel', '~> 1.8'
  spec.add_development_dependency 'factory_bot', '~> 6.1'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'webmock', '~> 3.11'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.3.6')
  spec.metadata['inferno_test_kit'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.files = `[ -d .git ] && git ls-files -z lib config/presets LICENSE`.split("\x0")

  spec.require_paths = ['lib']
end
