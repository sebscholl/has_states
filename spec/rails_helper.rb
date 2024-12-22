# frozen_string_literal: true

require 'spec_helper'

# Load dummy Rails app if in Rails context
ENV['RAILS_ENV'] = 'test'
require File.expand_path('dummy/config/environment.rb', __dir__)

# Load support files
require_relative 'support/factory_bot'
require_relative 'support/shoulda_matchers'
require_relative 'support/database_cleaner'

RSpec.configure do |config|
  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
  # ... rest of your RSpec configuration
end
