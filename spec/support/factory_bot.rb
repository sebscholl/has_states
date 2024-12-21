# frozen_string_literal: true

require "factory_bot"
require_relative "../factories/has_states"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
