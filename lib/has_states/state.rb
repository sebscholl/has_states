# frozen_string_literal: true

module HasStates
  class State < ActiveRecord::Base
    self.table_name = 'has_states_states'

    belongs_to :stateable, polymorphic: true

    validate :status_is_configured
    validate :state_type_is_configured

    after_save :trigger_callbacks, if: :saved_change_to_status?
  
    def self.generate_scopes!
      generate_state_type_scopes
    end

    def self.generate_predicates!
      generate_status_predicates
    end

    private

    def self.generate_state_type_scopes
      HasStates.configuration.state_types.each do |state_type|
        scope state_type, -> { where(state_type: state_type) }
      end
    end

    def self.generate_status_predicates
      HasStates.configuration.statuses.each do |status_name|
        define_method(:"#{status_name}?") do
          status == status_name
        end
      end
    end

    def status_is_configured
      return if HasStates.configuration.statuses.include?(status)

      errors.add(:status, 'is not configured')
    end

    def state_type_is_configured
      return if HasStates.configuration.state_types.include?(state_type)

      errors.add(:state_type, 'is not configured')
    end

    def trigger_callbacks
      HasStates.configuration.matching_callbacks(self).each do |callback|
        callback.call(self)
      end
    end
  end
end
