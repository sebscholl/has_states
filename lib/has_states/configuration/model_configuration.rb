module HasStates
  class Configuration
    class ModelConfiguration
      attr_reader :model_class, :state_types

      def initialize(model_class)
        @model_class = model_class
        @state_types = {}
      end

      def state_type(name, &block)
        type = StateTypeConfiguration.new(name)
        
        yield(type) if block_given?
        
        @state_types[name.to_s] = type
        
        generate_state_type_scope(name)
        generate_status_predicates(type.statuses)
      end

      private

      def generate_state_type_scope(state_type)
        HasStates::State.scope state_type, -> { where(state_type: state_type) }
      end

      def generate_status_predicates(statuses)
        statuses.each do |status_name|
          HasStates::State.define_method(:"#{status_name}?") do
            status == status_name
          end
        end
      end
    end
  end
end 