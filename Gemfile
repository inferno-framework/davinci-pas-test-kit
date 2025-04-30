# frozen_string_literal: true

source "https://rubygems.org"

gem 'smart_app_launch_test_kit', git: 'https://github.com/inferno-framework/smart-app-launch-test-kit.git', branch: 'client_authorization_code_tests'
gem 'udap_security_test_kit', git: 'https://github.com/inferno-framework/udap-security-test-kit.git', branch: 'client_authorization_code_tests'

gemspec

gem "rubocop"
gem 'rubocop-rspec', require: false

gem "rubocop-rake", "~> 0.6.0"

group :development, :test do
  gem 'debug'
  gem 'rack-test'
  # This should not be necessary but we are including it to address internal team issue
  # where the Ruby method of running tests don't work without it.
  gem 'foreman'
end
