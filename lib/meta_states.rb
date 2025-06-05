# frozen_string_literal: true

require 'active_record'
require 'meta_states/version'
require 'meta_states/configuration'
require 'meta_states/configuration/model_configuration'
require 'meta_states/configuration/state_type_configuration'

module MetaStates
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      Configuration.instance
    end
  end
end

require 'meta_states/base'
require 'meta_states/state'
require 'meta_states/callback'
require 'meta_states/stateable'
require 'meta_states/railtie' if defined?(Rails)
