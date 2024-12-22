# frozen_string_literal: true

module HasStates
  class Install
    include ActiveRecord::Tasks

    def self.install
      new.install
    end

    def install
      create_migration
    end

    private

    def create_migration
      timestamp = Time.current.strftime('%Y%m%d%H%M%S')
      template_path = File.expand_path('../templates/migration.rb', __dir__)
      target_path = "db/migrate/#{timestamp}_create_has_states_tables.rb"

      FileUtils.cp(template_path, target_path)
      Rails.logger.debug { "Created has_states migration #{target_path}" }
    end
  end
end
