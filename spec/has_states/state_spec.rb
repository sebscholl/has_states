# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HasStates::State, type: :model do
  subject { build(:state) }

  before do
    HasStates.configure do |config|
      config.state_types = %w[kyc]
      config.statuses = %w[pending completed]
    end
  end

  describe 'validations' do
    context 'status' do
      it 'validates status presence' do
        expect(subject).not_to allow_value(nil).for(:status)
      end

      it 'validates status is configured' do
        expect(subject).to allow_value('pending').for(:status)
      end

      it 'validates status that is not configured' do
        expect(subject).not_to allow_value('invalid').for(:status)
      end
    end

    context 'state_type' do
      it 'validates state_type presence' do
        expect(subject).not_to allow_value(nil).for(:state_type)
      end

      it 'validates state_type is configured' do
        expect(subject).to allow_value('kyc').for(:state_type)
      end

      it 'validates state_type that is not configured' do
        expect(subject).not_to allow_value('invalid').for(:state_type)
      end
    end
  end

  describe 'scopes' do
    let(:state) { create(:state, state_type: 'kyc') }

    it 'defines a scope for each state type' do
      expect(described_class.kyc).to eq([state])
    end
  end

  describe 'instance methods' do
    let(:state) { create(:state, state_type: 'kyc', status: 'pending') }

    HasStates.configuration.statuses.each do |status|
      it 'defines a method for each status' do
        expect(state).to respond_to("#{status}?")
      end
    end

    it 'returns true if the status is pending' do
      expect(state.pending?).to be(true)
    end

    it 'returns false if the status is not completed' do
      expect(state.completed?).to be(false)
    end
  end
end
