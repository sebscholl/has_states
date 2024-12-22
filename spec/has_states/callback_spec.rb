# frozen_string_literal: true

require 'rails_helper'

# spec/has_states/callback_spec.rb
RSpec.describe HasStates::Callback do
  let(:state) { double('state', state_type: 'kyc', status: 'completed') }
  let(:block) { ->(_s) { :called } }

  describe '#matches?' do
    context 'with state type only' do
      let(:callback) { described_class.new('kyc', {}, block) }

      it 'matches on state type' do
        expect(callback.matches?(state)).to be true
      end

      it "doesn't match different state type" do
        different_state = double('state', state_type: 'identity')
        expect(callback.matches?(different_state)).to be false
      end
    end

    context 'with status conditions' do
      let(:callback) { described_class.new('kyc', { to: 'completed' }, block) }

      it 'matches when conditions are met' do
        expect(callback.matches?(state)).to be true
      end

      it "doesn't match when conditions aren't met" do
        pending_state = double('state', state_type: 'kyc', status: 'pending')
        expect(callback.matches?(pending_state)).to be false
      end
    end

    context 'with from condition' do
      let(:callback) { described_class.new('kyc', { from: 'pending' }, block) }
      let(:state_with_history) do
        double('state',
               state_type: 'kyc',
               status: 'completed',
               status_before_last_save: 'pending')
      end

      it 'matches when previous status matches' do
        expect(callback.matches?(state_with_history)).to be true
      end
    end
  end

  describe '#call' do
    let(:callback) { described_class.new('kyc', {}, block) }

    it 'executes the stored block with the state' do
      expect(callback.call(state)).to eq(:called)
    end
  end
end
