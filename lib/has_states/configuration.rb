# frozen_string_literal: true

module HasStates
  class Configuration
    include Singleton

    attr_reader :callbacks, :model_configurations

    def initialize
      @callbacks = {}
      @next_callback_id = 0
      @model_configurations = {}
    end

    def configure_model(model_class, &block)
      unless model_class.is_a?(Class) && model_class < ActiveRecord::Base
        raise ArgumentError, "#{model_class} must be an ActiveRecord model"
      end

      model_config = Configuration::ModelConfiguration.new(model_class)
      
      yield(model_config)

      @model_configurations[model_class] = model_config
      model_class.include(Stateable) unless model_class.included_modules.include?(Stateable)
    end

    def valid_status?(model_class, state_type, status)
      return false unless @model_configurations[model_class]&.state_types[state_type.to_s]
      @model_configurations[model_class].state_types[state_type.to_s].statuses.include?(status)
    end

    def valid_state_type?(model_class, state_type)
      @model_configurations[model_class]&.state_types&.key?(state_type.to_s)
    end

    def on(state_type, id: nil, **conditions, &block)
      callback = Callback.new(state_type, conditions, block)
      callback_id = id&.to_sym || generate_callback_id
      @callbacks[callback_id] = callback
      callback
    end

    def off(callback_or_id)
      if callback_or_id.is_a?(Callback)
        @callbacks.delete_if { |_, cb| cb == callback_or_id }
      else
        @callbacks.delete(callback_or_id)
      end
    end

    def matching_callbacks(state)
      @callbacks.values.select { |callback| callback.matches?(state) }
    end

    def clear_callbacks!
      @callbacks = {}
    end

    def state_types_for(model_class)
      @model_configurations[model_class]&.state_types
    end

    def statuses_for(model_class, state_type)
      @model_configurations[model_class]&.state_types[state_type.to_s]&.statuses
    end

    private

    def generate_callback_id
      @next_callback_id += 1
      :"callback_#{@next_callback_id}"
    end
  end
end
