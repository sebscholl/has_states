# frozen_string_literal: true

module HasStates
  class Configuration
    include Singleton

    attr_reader :callbacks, :models, :state_types, :statuses

    def initialize
      @models = []
      @statuses = []
      @callbacks = {}
      @state_types = []
      @next_callback_id = 0
    end

    def models=(model_names)
      @models = Array(model_names)
      include_stateable_in_models
    end

    def state_types=(types)
      @state_types = Array(types)
      State.generate_scopes!
    end

    def statuses=(statuses)
      @statuses = Array(statuses)
      State.generate_predicates!
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

    private

    def include_stateable_in_models
      @models.each do |model_name|
        model = model_name.to_s.classify.constantize
        model.include(Stateable) unless model.included_modules.include?(Stateable)
      end
    rescue NameError => e
      raise "Could not find model: #{e.message}"
    end

    def generate_callback_id
      @next_callback_id += 1
      :"callback_#{@next_callback_id}"
    end
  end
end
