# frozen_string_literal: true

# spec/has_states/configuration_spec.rb
require 'rails_helper'

RSpec.describe HasStates::Configuration do
  let(:configuration) { described_class.instance }

  before do
    configuration.clear_callbacks!
    configuration.model_configurations.clear
  end

  describe 'model configuration' do
    it 'configures models with their state types and statuses' do
      configuration.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = %w[pending completed]
        end
      end

      expect(configuration.valid_status?(User, 'kyc', 'pending')).to be true
      expect(configuration.valid_status?(User, 'kyc', 'invalid')).to be false
    end

    it 'allows different statuses for different state types' do
      configuration.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = %w[pending verified]
        end

        model.state_type :onboarding do |type|
          type.statuses = %w[started completed]
        end
      end

      expect(configuration.valid_status?(User, 'kyc', 'verified')).to be true
      expect(configuration.valid_status?(User, 'onboarding', 'verified')).to be false
      expect(configuration.valid_status?(User, 'onboarding', 'completed')).to be true
    end

    it 'allows different configurations for different models' do
      configuration.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = %w[pending verified]
        end
      end

      configuration.configure_model Company do |model|
        model.state_type :onboarding do |type|
          type.statuses = %w[pending active]
        end
      end

      expect(configuration.valid_state_type?(User, 'kyc')).to be true
      expect(configuration.valid_state_type?(Company, 'kyc')).to be false
      expect(configuration.valid_state_type?(Company, 'onboarding')).to be true
    end

    it 'automatically includes Stateable in configured models' do
      configuration.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = ['pending']
        end
      end

      expect(User.included_modules).to include(HasStates::Stateable)
    end

    it 'raises error for non-ActiveRecord models' do
      expect do
        configuration.configure_model String do |model|
          model.state_type :test
        end
      end.to raise_error(ArgumentError, /must be an ActiveRecord model/)
    end

    it 'allows setting a limit on the number of states' do
      configuration.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = %w[pending completed]
          type.limit = 2
        end
      end

      expect(configuration.limit_for(User, 'kyc')).to eq(2)
    end

    it 'returns nil for limit when no limit is set' do
      configuration.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = %w[pending completed]
        end
      end

      expect(configuration.limit_for(User, 'kyc')).to be_nil
    end

    context 'when a metadata schema is set' do
      let(:schema) do
        {
          type: :object,
          properties: {
            name: { type: :string },
            age: { type: :integer, minimum: 18 }
          },
          required: %i[name age]
        }
      end

      before do
        configuration.configure_model User do |model|
          model.state_type :kyc do |type|
            type.statuses = %w[pending completed]
            type.metadata_schema = schema
          end
        end
      end

      it 'allows setting a metadata schema for validation' do
        expect(configuration.metadata_schema_for(User, 'kyc')).to eq(schema)
      end
    end

    it 'returns nil for metadata_schema when no schema is set' do
      configuration.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = %w[pending completed]
        end
      end

      expect(configuration.metadata_schema_for(User, 'kyc')).to be_nil
    end
  end

  describe 'callbacks' do
    let(:state_completed) { create(:state, state_type: 'kyc', status: 'completed') }

    before do
      configuration.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = %w[pending completed failed]
        end
      end

      configuration.on(:kyc, id: :failed_callback, to: 'failed') { |_s| :kyc_failed }
      configuration.on(:kyc, id: :pending_callback, to: 'pending') { |_s| :kyc_pending }
      configuration.on(:kyc, id: :complete_callback, to: 'completed') { |_s| :kyc_completed }
    end

    describe '#on' do
      it 'registers callbacks' do
        expect(configuration.callbacks.size).to eq(3)
      end

      it 'matches callbacks for the right state' do
        matching = configuration.matching_callbacks(state_completed)

        expect(matching.length).to eq(1)
      end

      it 'registers callbacks with auto-generated ids' do
        configuration.on(:kyc) { |_s| :some_action }
        expect(configuration.callbacks.keys.last).to match(/\Acallback_\d+\z/)
      end

      it 'registers callbacks with custom ids' do
        configuration.on(:kyc, id: :my_custom_callback) { |_s| :some_action }
        expect(configuration.callbacks.keys).to include(:my_custom_callback)
      end

      it 'converts string ids to symbols' do
        configuration.on(:kyc, id: 'my_string_id') { |_s| :some_action }
        expect(configuration.callbacks.keys).to include(:my_string_id)
      end
    end

    describe '#off' do
      it 'removes a callback by id' do
        configuration.on(:kyc, id: :removable) { |_s| :some_action }
        expect { configuration.off(:removable) }
          .to change { configuration.callbacks.size }.by(-1)
      end

      it 'removes a callback by callback object' do
        callback = configuration.on(:kyc) { |_s| :some_action }
        expect { configuration.off(callback) }
          .to change { configuration.callbacks.size }.by(-1)
      end

      it 'properly removes callback when given a callback object' do
        callback = configuration.on(:kyc, id: :test) { |_s| :some_action }
        expect(configuration.callbacks.values).to include(callback)

        configuration.off(callback)
        expect(configuration.callbacks.values).not_to include(callback)
      end
    end

    describe '#clear_callbacks!' do
      it 'removes all callbacks' do
        expect { configuration.clear_callbacks! }.to change { configuration.callbacks.size }.to(0)
      end
    end

    describe '#matching_callbacks' do
      it 'finds callbacks matching state type and conditions regardless of id' do
        configuration.clear_callbacks!
        configuration.on(:kyc, id: :complete_callback, to: 'completed') { |_s| :kyc_completed }

        matching = configuration.matching_callbacks(state_completed)

        expect(matching.size).to eq(1)
        expect(matching.first.call(state_completed)).to eq(:kyc_completed)
      end
    end
  end
end
