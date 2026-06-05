# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in time_range_uniqueness.gemspec
gemspec

activerecord_version = ENV.fetch('ACTIVERECORD_VERSION', nil)
gem 'activerecord', "~> #{activerecord_version}.0" if activerecord_version

group :development, :test do
  gem 'dotenv'
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rspec'
end
