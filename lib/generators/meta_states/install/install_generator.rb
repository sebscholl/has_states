# frozen_string_literal: true

require 'rails/generators'

module MetaStates
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    TEMPLATES = [
      {
        source: 'create_meta_states_states.rb.erb',
        destination: 'db/migrate/%s_create_meta_states_states.rb'
      },
      {
        source: 'create_indexes_on_meta_states_states.rb.erb',
        destination: 'db/migrate/%s_create_indexes_on_meta_states_states.rb'
      },
      {
        source: 'initializer.rb.erb',
        destination: 'config/initializers/meta_states.rb'
      }
    ].freeze

    def install
      puts 'Installing MetaStates...'

      TEMPLATES.each do |template|
        make_template(**template)
      end

      puts 'MetaStates installed successfully!'
    end

    private

    def make_template(source:, destination:)
      timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
      destination %= timestamp if destination.include?('%s')

      template(source, destination)
    end
  end
end
