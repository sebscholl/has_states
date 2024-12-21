# frozen_string_literal: true

module HasStates
  class Configuration
    include Singleton

    attr_accessor :models, :state_types, :statuses
    attr_reader :callbacks

    def initialize
      @models = []
      @statuses = []
      @callbacks = []
      @state_types = []
    end

    def on(state_type, **conditions, &block)
      callback = Callback.new(state_type, conditions, block)
      @callbacks << callback
      callback
    end

    def off(callback)
      @callbacks.delete(callback)
    end

    def matching_callbacks(state)
      @callbacks.select { |callback| callback.matches?(state) }
    end

    def clear_callbacks!
      @callbacks = []
    end
  end
end
