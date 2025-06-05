# frozen_string_literal: true

module MetaStates
  class Railtie < Rails::Railtie
  end
end

require 'generators/meta_states/install/install_generator'
