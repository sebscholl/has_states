# frozen_string_literal: true

module HasStates
  class Railtie < Rails::Railtie
  end
end

require 'generators/has_states/install/install_generator'
