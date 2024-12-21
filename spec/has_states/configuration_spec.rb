# frozen_string_literal: true

# spec/has_states/configuration_spec.rb
require "rails_helper"

RSpec.describe HasStates::Configuration do
  let(:configuration) { described_class.instance }

  describe "defaults" do
    it "initializes with empty arrays" do
      expect(configuration.models).to be_empty
      expect(configuration.statuses).to be_empty
      expect(configuration.state_types).to be_empty
    end
  end

  describe "#statuses=" do
    it "sets statuses and reloads configuration" do
      expect(HasStates::State).to receive(:generate_scopes!)

      HasStates.configure do |config|
        config.statuses = %w[pending completed]
      end

      expect(configuration.statuses).to eq(%w[pending completed])
    end
  end

  describe "#state_types=" do
    it "sets state_types and reloads configuration" do
      expect(HasStates::State).to receive(:generate_scopes!)

      HasStates.configure do |config|
        config.state_types = %w[kyc]
      end

      expect(configuration.state_types).to eq(%w[kyc])
    end
  end

  describe "callbacks" do
    let(:state_type) { "kyc" }
    let(:block) { ->(_state) { puts "called" } }
    let(:state_completed) { FactoryBot.create(:state, state_type: "kyc", status: "completed") }

    before do
      # Clear all callbacks
      HasStates.configuration.clear_callbacks!

      # Add basic configuration
      HasStates.configure do |config|
        config.state_types = [state_type]
        config.statuses = %w[pending completed failed]
        # Add a callbacks
        configuration.on(:kyc, to: "failed") { |_s| :kyc_failed }
        configuration.on(:kyc, to: "pending") { |_s| :kyc_pending }
        configuration.on(:kyc, to: "completed") { |_s| :kyc_completed }
      end
    end

    describe "#on" do
      it "registers callbacks" do
        expect(configuration.callbacks.size).to eq(3)
      end

      it "matches callbacks for the right state" do
        matching = configuration.matching_callbacks(state_completed)

        expect(matching.length).to eq(1)
      end
    end

    describe "#off" do
      it "removes a specific callback" do
        callback = configuration.callbacks.first

        expect { configuration.off(callback) }.to change { configuration.callbacks.size }.by(-1)
      end
    end

    describe "#clear_callbacks!" do
      it "removes all callbacks" do
        expect { configuration.clear_callbacks! }.to change { configuration.callbacks.size }.to(0)
      end
    end

    describe "#matching_callbacks" do
      it "finds callbacks matching state type and conditions" do
        matching = configuration.matching_callbacks(state_completed)

        expect(matching.size).to eq(1)
        expect(matching.first.call(state_completed)).to eq(:kyc_completed)
      end
    end
  end
end
