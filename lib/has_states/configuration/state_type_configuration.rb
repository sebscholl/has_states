# frozen_string_literal: true

module HasStates
  class Configuration
    class StateTypeConfiguration
      attr_reader :name
      attr_accessor :statuses

      def initialize(name)
        @name = name
        @statuses = []
      end
    end
  end
end
