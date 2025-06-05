# frozen_string_literal: true

module MetaStates
  class Configuration
    class StateTypeConfiguration
      attr_reader :name
      attr_accessor :statuses, :limit, :metadata_schema

      def initialize(name)
        @name = name
        @statuses = []
        @limit = nil
        @metadata_schema = nil
      end
    end
  end
end
