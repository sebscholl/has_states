# frozen_string_literal: true

module HasStates
  class Configuration
    class StateTypeConfiguration
      attr_reader :name
      attr_accessor :statuses, :limit

      def initialize(name)
        @name = name
        @statuses = []
        @limit = nil
      end
    end
  end
end
