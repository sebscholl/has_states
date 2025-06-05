# frozen_string_literal: true

require 'json-schema'

module MetaStates
  class Base < ActiveRecord::Base
    self.table_name = 'meta_states_states'

    belongs_to :stateable, polymorphic: true

    validate :status_is_configured
    validate :state_type_is_configured
    validate :state_limit_not_exceeded, on: :create
    validate :metadata_conforms_to_schema, if: -> { metadata.present? }

    after_commit :trigger_callbacks, if: :saved_change_to_status?

    private

    def status_is_configured
      return if MetaStates.configuration.valid_status?(
        stateable_type.constantize,
        state_type,
        status
      )

      errors.add(:status, 'is not configured')
    end

    def state_type_is_configured
      return if MetaStates.configuration.valid_state_type?(
        stateable_type.constantize,
        state_type
      )

      errors.add(:state_type, 'is not configured')
    end

    def state_limit_not_exceeded
      return unless (limit = MetaStates.configuration.limit_for(
        stateable_type.constantize,
        state_type
      ))

      return unless stateable

      current_count = stateable.states.where(state_type: state_type).count
      return if current_count < limit

      errors.add(:base, "maximum number of #{state_type} states (#{limit}) reached")
    end

    def metadata_conforms_to_schema
      return unless (schema = MetaStates.configuration.metadata_schema_for(
        stateable_type.constantize,
        state_type
      ))

      JSON::Validator.validate!(schema, metadata, strict: true)
    rescue JSON::Schema::ValidationError => e
      errors.add(:metadata, "does not conform to schema: #{e.message}")
    end

    def trigger_callbacks
      MetaStates.configuration.matching_callbacks(self).each do |callback|
        callback.call(self)
      end
    end
  end
end
