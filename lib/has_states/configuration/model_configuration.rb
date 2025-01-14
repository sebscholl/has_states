# frozen_string_literal: true

module HasStates
  class Configuration
    class ModelConfiguration
      attr_reader :model_class, :state_types

      def initialize(model_class)
        @model_class = model_class
        @state_types = {}
      end

      def state_type(name)
        type = StateTypeConfiguration.new(name)

        yield(type) if block_given?

        @state_types[name.to_s] = type

        # HasStates::State model method generators
        generate_state_type_scope(name)
        generate_status_predicates(type.statuses)

        # Included model method generators
        generate_state_type_queries(name)
        generate_state_type_status_predicates(name, type.statuses)
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

      def generate_state_type_queries(state_type)
        # Singular for finding the most recent state of a given type and status
        @model_class.define_method(:"#{state_type}") do
          states.where(state_type: state_type).order(created_at: :desc).first
        end

        # Plural for finding all states of a given type and status
        @model_class.define_method(:"#{ActiveSupport::Inflector.pluralize(state_type)}") do
          states.where(state_type: state_type).order(created_at: :desc)
        end
      end

      def generate_state_type_status_predicates(state_type, statuses)
        statuses.each do |status_name|
          @model_class.define_method(:"#{state_type}_#{status_name}?") do
            states.where(state_type: state_type, status: status_name).exists?
          end
        end
      end
    end
  end
end
