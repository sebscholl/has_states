# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetaStates::State, type: :model do
  subject { build(:state) }

  before do
    MetaStates.configuration.clear_callbacks!
    MetaStates.configuration.model_configurations.clear

    MetaStates.configure do |config|
      config.configure_model User do |model|
        model.state_type :kyc do |type|
          type.statuses = %w[pending completed]
        end

        model.state_type :onboarding do |type|
          type.statuses = %w[pending completed]
        end
      end
    end
  end

  describe 'indexes' do
    it 'defines an index on stateable_type and stateable_id' do
      expect(subject).to have_db_index(%i[stateable_type stateable_id])
    end

    it 'defines an index on stateable_id and state_type' do
      expect(subject).to have_db_index(%i[stateable_id state_type])
    end

    it 'defines an index on stateable_id, state_type, and status' do
      expect(subject).to have_db_index(%i[stateable_id state_type status])
    end

    it 'defines an index on stateable_id, state_type, and created_at' do
      expect(subject).to have_db_index(%i[stateable_id state_type created_at])
    end

    it 'defines an index on stateable_id, state_type, status, and created_at' do
      expect(subject).to have_db_index(%i[stateable_id state_type status created_at])
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
    let(:model_config) { MetaStates.configuration.model_configurations[User] }
    let(:all_statuses) { model_config.state_types.values.flat_map(&:statuses).uniq }

    context 'predicate methods' do
      it 'defines predicate methods for all configured statuses' do
        all_statuses.each do |status|
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

  describe 'metadata' do
    let(:user) { FactoryBot.create(:user) }

    it 'stores and retrieves simple metadata' do
      state = user.add_state('kyc', metadata: { reason: 'documents_missing' })
      expect(state.metadata['reason']).to eq('documents_missing')
    end

    it 'stores and retrieves nested metadata' do
      metadata = {
        documents: {
          passport: { status: 'rejected', reason: 'expired' },
          utility_bill: { status: 'pending' }
        }
      }

      state = user.add_state('kyc', metadata: metadata)
      expect(state.metadata['documents']['passport']['reason']).to eq('expired')
    end

    it 'handles arrays in metadata' do
      metadata = {
        missing_documents: %w[passport utility_bill],
        review_history: [
          { date: '2024-01-01', status: 'rejected' },
          { date: '2024-01-02', status: 'approved' }
        ]
      }

      state = user.add_state('kyc', metadata: metadata)
      expect(state.metadata['missing_documents']).to eq(%w[passport utility_bill])
      expect(state.metadata['review_history'].size).to eq(2)
    end

    it 'handles different data types' do
      metadata = {
        string_value: 'test',
        integer_value: 42,
        float_value: 42.5,
        boolean_value: true,
        null_value: nil,
        date_value: '2024-01-01'
      }

      state = user.add_state('kyc', metadata: metadata)
      expect(state.metadata['string_value']).to eq('test')
      expect(state.metadata['integer_value']).to eq(42)
      expect(state.metadata['float_value']).to eq(42.5)
      expect(state.metadata['boolean_value']).to be true
      expect(state.metadata['null_value']).to be_nil
      expect(state.metadata['date_value']).to eq('2024-01-01')
    end

    it 'defaults to empty hash when no metadata provided' do
      state = user.add_state('kyc')
      expect(state.metadata).to eq({})
    end

    it 'persists metadata across database reads' do
      state = user.add_state('kyc', metadata: { key: 'value' })
      reloaded_state = MetaStates::State.find(state.id)
      expect(reloaded_state.metadata['key']).to eq('value')
    end
  end

  describe 'callbacks' do
    let(:user) { create(:user) }
    let(:callback_executed) { false }

    before do
      MetaStates.configure do |config|
        config.configure_model User do |model|
          model.state_type :onboarding do |type|
            type.statuses = %w[pending completed]
          end
        end

        # Register a callback for when onboarding is completed
        config.on(:onboarding, id: :complete_onboarding, to: 'completed') do |state|
          state.stateable.update!(name: 'Onboarded User')
        end
      end
    end

    it 'executes callback when state changes to completed' do
      # Create initial pending state
      state = user.add_state('onboarding', status: 'pending')
      expect(user.name).not_to eq('Onboarded User')

      # Update to completed
      state.update!(status: 'completed')

      # Verify callback was executed
      expect(user.reload.name).to eq('Onboarded User')
    end

    it 'does not execute callback for other status changes' do
      state = user.add_state('onboarding', status: 'completed')
      user.update!(name: 'Original Name')

      # Update to pending
      state.update!(status: 'pending')

      # Verify callback was not executed
      expect(user.reload.name).to eq('Original Name')
    end
  end

  describe 'limited execution callbacks' do
    let(:user) { create(:user) }

    before do
      # Clear ALL configuration
      MetaStates.configuration.clear_callbacks!
      MetaStates.configuration.model_configurations.clear

      # Set up fresh configuration
      MetaStates.configure do |config|
        config.configure_model User do |model|
          model.state_type :onboarding do |type|
            type.statuses = %w[pending completed]
          end
        end
      end

      @execution_count = 0
    end

    it 'executes callback only specified number of times' do
      MetaStates.configure do |config|
        config.on(:onboarding, id: :counter, to: 'completed', times: 2) do |state|
          state.stateable.update!(name: "Execution #{@execution_count += 1}")
        end
      end

      # First execution
      state1 = user.add_state('onboarding', status: 'pending')
      state1.update!(status: 'completed')
      expect(user.reload.name).to eq('Execution 1')

      # Second execution
      state2 = user.add_state('onboarding', status: 'pending')
      state2.update!(status: 'completed')
      expect(user.reload.name).to eq('Execution 2')

      # Third execution - callback should be expired
      user.update!(name: 'Final Name')
      state3 = user.add_state('onboarding', status: 'pending')
      state3.update!(status: 'completed')
      expect(user.reload.name).to eq('Final Name') # Name shouldn't change
    end

    it 'keeps callback active indefinitely when times is not specified' do
      MetaStates.configure do |config|
        config.on(:onboarding, id: :infinite, to: 'completed') do |state|
          state.stateable.update!(name: "Execution #{@execution_count += 1}")
        end
      end

      3.times do |i|
        state = user.add_state('onboarding', status: 'pending')
        state.update!(status: 'completed')
        expect(user.reload.name).to eq("Execution #{i + 1}")
      end
    end

    it 'removes expired callbacks from configuration' do
      MetaStates.configure do |config|
        config.on(:onboarding, id: :one_time, to: 'completed', times: 1) do |state|
          state.stateable.update!(name: 'Executed')
        end
      end

      expect do
        state = user.add_state('onboarding', status: 'pending')
        state.update!(status: 'completed')
      end.to change { MetaStates.configuration.callbacks.size }.from(1).to(0)
    end
  end

  describe 'custom state types' do
    # Create a custom state class for testing
    class KYCState < MetaStates::Base
      validates :metadata, presence: true
      validate :required_metadata_fields

      private

      def required_metadata_fields
        return if metadata&.key?('document_type')

        errors.add(:metadata, 'must include document_type')
      end
    end

    let(:user) { create(:user) }

    it 'allows creation of custom state types' do
      state = user.add_state(
        'kyc',
        status: 'pending',
        metadata: { document_type: 'passport' },
        state_class: KYCState
      )

      expect(state).to be_valid
      expect(state).to be_a(KYCState)
    end

    it 'enforces custom validations' do
      expect do
        user.add_state(
          'kyc',
          status: 'pending',
          metadata: { other_field: 'value' },
          state_class: KYCState
        )
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        /Metadata must include document_type/
      )
    end

    it 'defaults to MetaStates::State when no state_class specified' do
      state = user.add_state('kyc', status: 'pending')

      expect(state).to be_a(MetaStates::State)
      expect(state).to be_valid
    end

    it 'maintains STI type across database reads' do
      state = user.add_state(
        'kyc',
        status: 'pending',
        metadata: { document_type: 'passport' },
        state_class: KYCState
      )

      reloaded_state = MetaStates::Base.find(state.id)
      expect(reloaded_state).to be_a(KYCState)
    end
  end
end
