# frozen_string_literal: true

module HasStates
  class Callback
    attr_reader :state_type, :conditions, :block, :max_executions
    attr_accessor :execution_count

    def initialize(state_type, conditions, block)
      @state_type = state_type
      @conditions = conditions
      @block = block
      @max_executions = conditions.delete(:times)
      @execution_count = 0
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

    def call(state)
      result = block.call(state)
      @execution_count += 1
      
      # Remove self from configuration if this was the last execution
      if expired?
        HasStates.configuration.off(self)
      end
      
      result
    end

    def expired?
      max_executions && execution_count >= max_executions
    end

    def ==(other)
      other.is_a?(self.class) &&
        other.state_type == state_type &&
        other.conditions == conditions &&
        other.block == block
    end

    alias eql? ==

    def hash
      [state_type, conditions, block].hash
    end
  end
end
