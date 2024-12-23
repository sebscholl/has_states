# frozen_string_literal: true

require 'rails/generators'

module HasStates
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def install
      puts 'Installing HasStates...'

      template(
        'create_has_states_states.rb.erb',
        "db/migrate/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_create_has_states_states.rb"
      )

      template(
        'initializer.rb.erb',
        'config/initializers/has_states.rb'
      )

      puts 'HasStates installed successfully!'
    end
  end
end
