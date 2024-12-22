# frozen_string_literal: true

# spec/has_states/configuration_spec.rb
require 'rails_helper'

RSpec.describe HasStates::Configuration do
  let(:configuration) { described_class.instance }

  before do
    # Reset configuration before each test
    configuration.clear_callbacks!
    configuration.models = []
    configuration.state_types = []
    configuration.statuses = []
  end

  describe 'defaults' do
    it 'initializes with empty arrays' do
      expect(configuration.models).to be_empty
      expect(configuration.statuses).to be_empty
      expect(configuration.state_types).to be_empty
    end
  end

  describe '#statuses=' do
    it 'sets statuses and reloads configuration' do
      expect(HasStates::State).to receive(:generate_predicates!)

      HasStates.configure do |config|
        config.statuses = %w[pending completed]
      end

      expect(configuration.statuses).to eq(%w[pending completed])
    end
  end

  describe '#state_types=' do
    it 'sets state_types and reloads configuration' do
      expect(HasStates::State).to receive(:generate_scopes!)

      HasStates.configure do |config|
        config.state_types = %w[kyc]
      end

      expect(configuration.state_types).to eq(%w[kyc])
    end
  end

  describe 'callbacks' do
    let(:state_type) { 'kyc' }
    let(:block) { ->(_state) { puts 'called' } }
    let(:state_completed) { FactoryBot.create(:state, state_type: 'kyc', status: 'completed') }

    before do
      # Clear all callbacks
      HasStates.configuration.clear_callbacks!

      # Add basic configuration
      HasStates.configure do |config|
        config.state_types = [state_type]
        config.statuses = %w[pending completed failed]
        # Add callbacks with explicit IDs
        configuration.on(:kyc, id: :failed_callback, to: 'failed') { |_s| :kyc_failed }
        configuration.on(:kyc, id: :pending_callback, to: 'pending') { |_s| :kyc_pending }
        configuration.on(:kyc, id: :complete_callback, to: 'completed') { |_s| :kyc_completed }
      end
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
        callback = configuration.on(:kyc) { |_s| :some_action }
        expect(configuration.callbacks.keys.last).to match(/\Acallback_\d+\z/)
      end

      it 'registers callbacks with custom ids' do
        callback = configuration.on(:kyc, id: :my_custom_callback) { |_s| :some_action }
        expect(configuration.callbacks.keys).to include(:my_custom_callback)
      end

      it 'converts string ids to symbols' do
        callback = configuration.on(:kyc, id: 'my_string_id') { |_s| :some_action }
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

  describe '#models=' do
    it 'includes Stateable in configured models' do
      HasStates.configure do |config|
        config.models = ['User']
      end

      expect(User.included_modules).to include(HasStates::Stateable)
    end

    it 'handles symbol model names' do
      HasStates.configure do |config|
        config.models = [:user]
      end

      expect(User.included_modules).to include(HasStates::Stateable)
    end

    it 'raises error for non-existent models' do
      expect {
        HasStates.configure do |config|
          config.models = ['NonExistentModel']
        end
      }.to raise_error(/Could not find model/)
    end

    it 'does not double-include Stateable' do
      HasStates.configure do |config|
        config.models = ['User']
      end

      expect(User).not_to receive(:include)
      
      HasStates.configure do |config|
        config.models = ['User']
      end
    end
  end
end
