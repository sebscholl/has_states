# frozen_string_literal: true

module MetaStates
  class Configuration
    include Singleton

    attr_reader :callbacks, :model_configurations

    def initialize
      @callbacks = {}
      @next_callback_id = 0
      @model_configurations = {}
    end

    # Configure a model to use MetaStates
    # @param model_class [Class] The model class to configure
    # @return [Configuration::ModelConfiguration] The model configuration
    # @raise [ArgumentError] If the model class is not an ActiveRecord model
    def configure_model(model_class)
      unless model_class.is_a?(Class) && model_class < ActiveRecord::Base
        raise ArgumentError, "#{model_class} must be an ActiveRecord model"
      end

      model_config = Configuration::ModelConfiguration.new(model_class)

      yield(model_config)

      @model_configurations[model_class] = model_config
      model_class.include(Stateable) unless model_class.included_modules.include?(Stateable)
    end

    # Check if a status is valid for a given state type
    # @param model_class [Class] The model class
    # @param state_type [String] The state type
    # @param status [String] The status
    # @return [Boolean] True if the status is valid, false otherwise
    def valid_status?(model_class, state_type, status)
      return false unless @model_configurations[model_class]&.state_types&.dig(state_type.to_s)

      @model_configurations[model_class].state_types[state_type.to_s].statuses.include?(status)
    end

    # Check if a state type is valid for a given model
    # @param model_class [Class] The model class
    # @param state_type [String] The state type
    # @return [Boolean] True if the state type is valid, false otherwise
    def valid_state_type?(model_class, state_type)
      @model_configurations[model_class]&.state_types&.key?(state_type.to_s)
    end

    # Get the configuration for a given state type
    # @param model_class [Class] The model class
    # @param state_type [String] The state type
    # @return [Configuration::StateTypeConfiguration] The state type configuration
    def config_for(model_class, state_type)
      @model_configurations[model_class]&.state_types&.dig(state_type.to_s)
    end

    # Get the state types for a given model
    # @param model_class [Class] The model class
    # @return [Hash] The state types for the model
    def state_types_for(model_class)
      @model_configurations[model_class]&.state_types
    end

    # Get the statuses for a given state type
    # @param model_class [Class] The model class
    # @param state_type [String] The state type
    # @return [Array] The statuses for the state type
    def statuses_for(model_class, state_type)
      return nil unless (config = config_for(model_class, state_type))

      config.statuses
    end

    # Get the limit for a given state type
    # @param model_class [Class] The model class
    # @param state_type [String] The state type
    # @return [Integer] The limit for the state type
    def limit_for(model_class, state_type)
      return nil unless (config = config_for(model_class, state_type))

      config.limit
    end

    # Get the metadata schema for a given state type
    # @param model_class [Class] The model class
    # @param state_type [String] The state type
    # @return [Hash] The metadata schema for the state type
    def metadata_schema_for(model_class, state_type)
      return nil unless (config = config_for(model_class, state_type))

      config.metadata_schema
    end

    # Register a callback for a given state type
    # @param state_type [String] The state type
    # @param id [Symbol] The callback id
    # @param conditions [Hash] The conditions for the callback
    # @param block [Proc] The callback block
    # @return [Callback] The callback
    def on(state_type, id: nil, **conditions, &block)
      callback = Callback.new(state_type, conditions, block)
      callback_id = id&.to_sym || generate_callback_id
      @callbacks[callback_id] = callback
      callback
    end

    # Remove a callback by id or callback object
    # @param callback_or_id [Symbol, Callback] The callback id or callback object
    # @return [Callback] The removed callback
    def off(callback_or_id)
      if callback_or_id.is_a?(Callback)
        @callbacks.delete_if { |_, cb| cb == callback_or_id }
      else
        @callbacks.delete(callback_or_id)
      end
    end

    # Get the callbacks that match a given state
    # @param state [State] The state
    # @return [Array] The matching callbacks
    def matching_callbacks(state)
      @callbacks.values.select { |callback| callback.matches?(state) }
    end

    # Clear all callbacks
    # @return [void]
    def clear_callbacks!
      @callbacks = {}
    end

    private

    # Generate a unique callback id
    # @return [Symbol] The generated callback id
    def generate_callback_id
      @next_callback_id += 1
      :"callback_#{@next_callback_id}"
    end
  end
end
