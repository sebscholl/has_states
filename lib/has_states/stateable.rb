# frozen_string_literal: true

module HasStates
  module Stateable
    extend ActiveSupport::Concern

    included do
      has_many :states, class_name: 'HasStates::State',
                        as: :stateable,
                        dependent: :destroy
    end

    # Instance methods for managing states
    def add_state(type, status: 'pending', metadata: {})
      states.create!(
        state_type: type,
        status: status,
        metadata: metadata
      )
    end
  end
end
