# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem 'subscriptions_test_kit', git: 'https://github.com/inferno-framework/subscriptions-test-kit.git', branch: 'release-0.13.0'

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
