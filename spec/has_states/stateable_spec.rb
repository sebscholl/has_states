require 'rails_helper'

RSpec.describe HasStates::Stateable do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include HasStates::Stateable
      include ActiveRecord::Model
    end
  end

  let(:user) { create(:user) } # Assuming you have a User factory

  before do
    # HasStates.configuration.clear_callbacks!
    # HasStates.configuration.model_configurations.clear

    HasStates.configure do |config|
      config.configure_model User do |model|
        model.state_type :test_type do |type|
          type.statuses = %w[pending completed]
        end

        model.state_type :other_test_type do |type|
          type.statuses = %w[pending completed]
        end
      end
    end
  end

  describe 'associations' do
    it 'has many states' do
      association = User.reflect_on_association(:states)

      expect(association.macro).to eq :has_many
      expect(association.options[:as]).to eq :stateable
      expect(association.options[:dependent]).to eq :destroy
      expect(association.options[:class_name]).to eq 'HasStates::Base'
    end
  end

  describe '#add_state' do
    context 'with default parameters' do
      it 'creates a new state with default values' do
        state = user.add_state('test_type')

        expect(state).to be_persisted
        expect(state.metadata).to eq({})
        expect(state.status).to eq 'pending'
        expect(state.state_type).to eq 'test_type'
        expect(state.type).to eq 'HasStates::State'
      end
    end

    context 'with custom parameters' do
      let(:metadata) { { key: 'value' } }

      it 'creates a new state with provided values' do
        state = user.add_state('test_type', status: 'completed', metadata: metadata)

        expect(state).to be_persisted
        expect(state.status).to eq 'completed'
        expect(state.state_type).to eq 'test_type'
        expect(state.type).to eq 'HasStates::State'
        expect(state.metadata).to eq metadata.as_json
      end
    end

    context 'with custom state class' do
      before(:all) do
        module HasStates
          class CustomState < State; end
        end
      end

      after(:all) do
        HasStates.send(:remove_const, :CustomState)
      end

      it 'creates a new state with the specified class' do
        state = user.add_state('test_type', state_class: HasStates::CustomState)

        expect(state).to be_persisted
        expect(state.type).to eq 'HasStates::CustomState'
      end
    end

    context 'when validation fails' do
      before do
        allow_any_instance_of(HasStates::Base).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'raises an ActiveRecord::RecordInvalid error' do
        expect { user.add_state('test_type') }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#current_state' do
    let!(:latest_state) { user.add_state('test_type', status: 'completed') }

    before do
      travel_to 1.day.ago do
        3.times { user.add_state('test_type', status: 'pending') }
        2.times { user.add_state('other_test_type', status: 'pending') }
      end
    end

    it 'returns the most recent state for the given type' do
      expect(user.current_state('test_type')).to eq latest_state
    end

    it 'returns nil when no state exists for the given type' do
      expect(user.current_state('nonexistent')).to be_nil
    end
  end

  describe '#current_states' do
    before do
      3.times { user.add_state('test_type', status: 'pending') }
      3.times { user.add_state('other_test_type', status: 'completed') }
    end

    it 'returns all states for the given type ordered by creation time' do
      test_types = user.current_states('test_type')

      expect(test_types.size).to eq 3
      expect(test_types).to eq test_types.sort_by(&:created_at).reverse
    end

    it 'returns empty relation when no states exist for the given type' do
      nonexistent_states = user.current_states('nonexistent')
      expect(nonexistent_states).to be_empty
      expect(nonexistent_states).to be_a(ActiveRecord::Relation)
    end
  end

  describe 'query methods' do
    before do
      2.times { user.add_state('test_type', status: 'pending') }
      2.times { user.add_state('other_test_type', status: 'pending') }
    end

    context 'find one methods' do
      it 'defines query one methods for configured states' do
        expect(user).to respond_to('test_type')
        expect(user).to respond_to('other_test_type')
      end

      it 'returns the most recent state for the given status' do
        expect(user.test_type).to eq user.current_state('test_type')
        expect(user.other_test_type).to eq user.current_state('other_test_type')
      end
    end

    context 'find many methods' do
      it 'defines query all methods for configured states' do
        expect(user).to respond_to('test_types')
        expect(user).to respond_to('other_test_types')
      end

      it 'returns all states for the given status ordered by creation time' do
        test_types = user.test_types
        other_test_types = user.other_test_types

        expect(test_types.size).to eq 2
        expect(other_test_types.size).to eq 2

        expect(test_types).to eq test_types.sort_by(&:created_at).reverse
        expect(other_test_types).to eq other_test_types.sort_by(&:created_at).reverse
      end
    end
  end

  # Optional: Test the destruction of associated states
  describe 'destroying the stateable object' do
    let!(:state) { user.add_state('test_type') }

    it 'destroys associated states when the user is destroyed' do
      expect { user.destroy }.to change { HasStates::Base.count }.by(-1)
    end
  end
end
