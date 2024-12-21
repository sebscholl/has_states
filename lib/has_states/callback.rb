# frozen_string_literal: true

module HasStates
  class Callback
    attr_reader :state_type, :conditions, :block

    def initialize(state_type, conditions, block)
      @state_type = state_type
      @conditions = conditions
      @block = block
    end

    def matches?(state)
      return false unless state.state_type == state_type.to_s

      conditions.all? do |key, expected_value|
        case key
        when :to
          state.status == expected_value
        when :from
          state.status_before_last_save == expected_value
        else
          state.public_send(key) == expected_value
        end
      end
    end

    delegate :call, to: :block
  end
end
