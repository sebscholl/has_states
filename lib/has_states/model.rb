# frozen_string_literal: true

module HasStates
  module Model
    extend ActiveSupport::Concern

    included do
      has_many :states,
               class_name: "HasStates::State::Base",
               as: :stateable,
               dependent: :destroy

      has_many :verifications,
               class_name: "HasStates::State::Verification",
               as: :stateable,
               dependent: :destroy
    end
  end
end
