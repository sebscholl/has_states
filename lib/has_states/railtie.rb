# frozen_string_literal: true

module HasStates
  class Railtie < Rails::Railtie
    initializer "has_states.setup" do; end

    rake_tasks do
      load "tasks/has_states_tasks.rake"
    end
  end
end
