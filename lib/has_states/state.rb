# frozen_string_literal: true

module HasStates
  class State < ActiveRecord::Base
    self.table_name = 'has_states_states'

    belongs_to :stateable, polymorphic: true

    validate :status_is_configured
    validate :state_type_is_configured

    after_initialize :define_status_methods

    after_save :trigger_callbacks, if: :saved_change_to_status?

    private

    def self.generate_scopes!
      define_status_scopes
    end

    def status_is_configured
      return if HasStates.configuration.statuses.include?(status)

      errors.add(:status, 'is not configured')
    end

    def state_type_is_configured
      return if HasStates.configuration.state_types.include?(state_type)

      errors.add(:state_type, 'is not configured')
    end

    # Define methods for each status on the instance.
    # Example: state.pending? => true
    def define_status_methods
      HasStates.configuration.statuses.each do |status_name|
        define_singleton_method(:"#{status_name}?") do
          status == status_name
        end
      end
    end

    # Define scopes for each state type on the class.
    # Example: State.kyc => [state]
    def self.define_status_scopes
      HasStates.configuration.state_types.each do |state_type|
        scope state_type, -> { where(state_type: state_type) }
      end
    end

    # Trigger callbacks when the status changes
    # Example: state.status = "completed" => triggers callbacks
    def trigger_callbacks
      HasStates.configuration.matching_callbacks(self).each do |callback|
        callback.call(self)
      end
    end
  end
end
