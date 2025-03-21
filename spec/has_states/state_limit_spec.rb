# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'State Limit Feature', type: :model do
  before do
    HasStates.configuration.clear_callbacks!
    HasStates.configuration.model_configurations.clear

    HasStates.configure do |config|
      config.configure_model User do |model|
        model.state_type :double_limit_state do |type|
          type.statuses = %w[pending completed]
          type.limit = 2
        end

        model.state_type :no_limit_state do |type|
          type.statuses = %w[pending completed]
          # No limit set for this type
        end

        model.state_type :single_limit_state do |type|
          type.statuses = %w[pending completed]
          type.limit = 1
        end
      end
    end
  end

  describe 'state limit validation' do
    let(:user) { create(:user) }

    context 'with no limit set' do
      it 'allows creating multiple states of the same type' do
        # Create multiple onboarding states (no limit)
        expect do
          3.times { user.add_state('no_limit_state', status: 'pending') }
        end.not_to raise_error

        expect(user.states.where(state_type: 'no_limit_state').count).to eq(3)
      end
    end

    context 'with a limit set' do
      it 'allows creating states up to the limit' do
        # Create double_limit_state states up to the limit (2)
        expect do
          2.times { user.add_state('double_limit_state', status: 'pending') }
        end.not_to raise_error

        expect(user.states.where(state_type: 'double_limit_state').count).to eq(2)
      end

      it 'prevents creating states beyond the limit' do
        # Create double_limit_state states up to the limit
        2.times { user.add_state('double_limit_state', status: 'pending') }

        # Try to create one more (exceeding the limit)
        expect do
          user.add_state('double_limit_state', status: 'pending')
        end.to raise_error(ActiveRecord::RecordInvalid, /maximum number of double_limit_state states/)
      end

      it 'enforces a limit of 1 correctly' do
        # Create one state
        user.add_state('single_limit_state', status: 'pending')

        # Try to create another one (exceeding the limit of 1)
        expect do
          user.add_state('single_limit_state', status: 'completed')
        end.to raise_error(ActiveRecord::RecordInvalid, /maximum number of single_limit_state states/)
      end
    end

    context 'with different state types' do
      it 'applies limits independently to each state type' do
        # Create states up to the limit for double_limit_state
        2.times { user.add_state('double_limit_state', status: 'pending') }

        # Create states for no_limit_state (no limit)
        3.times { user.add_state('no_limit_state', status: 'pending') }

        # Create one state for single_limit_state (limit 1)
        user.add_state('single_limit_state', status: 'pending')

        # Verify counts
        expect(user.states.where(state_type: 'double_limit_state').count).to eq(2)
        expect(user.states.where(state_type: 'no_limit_state').count).to eq(3)
        expect(user.states.where(state_type: 'single_limit_state').count).to eq(1)

        # Try to exceed limits
        expect do
          user.add_state('double_limit_state', status: 'completed')
        end.to raise_error(ActiveRecord::RecordInvalid, /maximum number of double_limit_state states/)

        expect do
          user.add_state('single_limit_state', status: 'completed')
        end.to raise_error(ActiveRecord::RecordInvalid, /maximum number of single_limit_state states/)

        # But can still add more no_limit_state states
        expect do
          user.add_state('no_limit_state', status: 'completed')
        end.not_to raise_error
      end
    end
  end
end
