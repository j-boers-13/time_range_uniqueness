# frozen_string_literal: true

require_relative 'lib/time_range_uniqueness/version'

Gem::Specification.new do |spec|
  spec.name = 'time_range_uniqueness'
  spec.version = TimeRangeUniqueness::VERSION
  spec.authors = ['j-boers-13']
  spec.email = ['jeroen.boers1@gmail.com']

  spec.summary = 'Easily set up time range uniqueness in Ruby On Rails.'
  spec.description = 'This gem helps you easily set up time range uniqueness constraints in PostgreSQL using ActiveRecord migrations and validations. It ensures that time ranges do not overlap within a table, supporting optional scoping of uniqueness.'
  spec.homepage = 'https://github.com/j-boers-13/time_range_uniqueness'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  # Metadata
  spec.metadata['source_code_uri'] = 'https://github.com/j-boers-13/time_range_uniqueness'
  spec.metadata['homepage_uri'] = 'https://github.com/j-boers-13/time_range_uniqueness'
  spec.metadata['changelog_uri'] = 'https://github.com/j-boers-13/time_range_uniqueness/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git Gemfile])
    end
  end

  spec.extra_rdoc_files = ['README.md']
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'activerecord', '>= 5.2', '< 8.0'
  spec.add_dependency 'pg', '>= 0.18'

  # Development dependencies
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rspec'
end