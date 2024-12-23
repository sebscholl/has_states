# frozen_string_literal: true


module HasStates
  module Generators; end

  class Railtie < Rails::Railtie
    config.app_generators do |g|
      g.templates.unshift File.expand_path('../generators', __dir__)
    end
  end
end

require 'has_states/generators/install/install_generator'
