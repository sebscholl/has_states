# frozen_string_literal: true

module HasStates
  module Stateable
    extend ActiveSupport::Concern

    included do
      has_many :states, class_name: "HasStates::State",
                        as: :stateable,
                        dependent: :destroy
    end

    # Instance methods for managing states
    def add_state(type, status: "pending", metadata: {})
      states.create!(
        state_type: type,
        status: status,
        metadata: metadata
      )
    end

    def states_of_type(type)
      states.where(state_type: type)
    end

    def current_state(type)
      states_of_type(type).order(created_at: :desc).first
    end

    def state_completed?(type)
      states_of_type(type).where(status: "completed").exists?
    end
  end
end
