# frozen_string_literal: true

require_relative 'boot'

require 'rails'

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Bundler.require(*Rails.groups)
require 'meta_states'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false
    config.api_only = false
  end
end
