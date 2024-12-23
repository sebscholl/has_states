# frozen_string_literal: true

module HasStates
  class Base < ActiveRecord::Base
    self.table_name = 'has_states_states'

    belongs_to :stateable, polymorphic: true

    validate :status_is_configured
    validate :state_type_is_configured

    after_save :trigger_callbacks, if: :saved_change_to_status?

    private

    def status_is_configured
      return if HasStates.configuration.valid_status?(
        stateable_type.constantize,
        state_type,
        status
      )

      errors.add(:status, 'is not configured')
    end

    def state_type_is_configured
      return if HasStates.configuration.valid_state_type?(
        stateable_type.constantize,
        state_type
      )

      errors.add(:state_type, 'is not configured')
    end

    def trigger_callbacks
      HasStates.configuration.matching_callbacks(self).each do |callback|
        callback.call(self)
      end
    end
  end
end 