# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rubocop"
gem 'rubocop-rspec', require: false

gem "rubocop-rake", "~> 0.6.0"

gem 'inferno_core',
    git: 'git@github.com:inferno-framework/inferno-core.git',
    branch: 'fi-3943-requirements-coverage-command'

group :development, :test do
  gem 'debug'
  gem 'rack-test'
  # This should not be necessary but we are including it to address internal team issue
  # where the Ruby method of running tests don't work without it.
  gem 'foreman'
end
