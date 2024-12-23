# frozen_string_literal: true

require 'active_record'
require 'has_states/version'
require 'has_states/configuration'
require 'has_states/configuration/model_configuration'
require 'has_states/configuration/state_type_configuration'

module HasStates
  class << self
    def configure
      yield(configuration)
    end
    
    def configuration
      Configuration.instance
    end
  end
end

require 'has_states/base'
require 'has_states/state'
require 'has_states/callback'
require 'has_states/stateable'
require 'has_states/railtie' if defined?(Rails)
