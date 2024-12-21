# frozen_string_literal: true

require_relative "lib/has_states/version"

Gem::Specification.new do |spec|
  spec.name = "has_states"
  spec.version = HasStates::VERSION
  spec.authors = ["Sebastian Scholl"]
  spec.email = ["sebscholl@gmail.com"]

  spec.summary = "Simple and flexible state management for Ruby objects"
  spec.description = '
    HasStates provides state management and event system capabilities for Ruby objects.
    It allows tracking states, state transitions, and triggering callbacks on state changes.
  '
  spec.homepage = "https://github.com/sebscholl/has_states"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["{lib,spec}/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "sqlite3"
end
