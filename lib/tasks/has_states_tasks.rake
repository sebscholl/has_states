# frozen_string_literal: true

namespace :has_states do
  desc 'Install HasStates migrations'
  task install: :environment do
    HasStates::Install.install
  end
end
