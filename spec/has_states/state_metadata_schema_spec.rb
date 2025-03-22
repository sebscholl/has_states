# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Metadata Schema Validation', type: :model do
  let(:user) { create(:user) }
  let(:schema) do
    {
      type: :object,
      properties: {
        name: { type: :string },
        age: {
          type: :integer,
          minimum: 18
        }
      },
      required: %i[name age]
    }
  end

  before do
    HasStates.configuration.clear_callbacks!
    HasStates.configuration.model_configurations.clear

    HasStates.configure do |config|
      config.configure_model User do |model|
        model.state_type :schema_enabled_state do |type|
          type.statuses = %w[pending completed rejected]
          type.metadata_schema = schema
        end

        model.state_type :no_schema_state do |type|
          type.statuses = %w[active inactive]
        end
      end
    end
  end

  describe 'validation' do
    context 'with a valid schema' do
      it 'validates valid metadata' do
        # Invalid metadata (too young < 18)
        expect do
          user.add_state('schema_enabled_state', status: 'pending', metadata: { name: 'John Doe', age: 17 })
        end.to raise_error(ActiveRecord::RecordInvalid, /did not have a minimum value of 18/)

        # Invalid metadata (missing required fields)
        expect do
          user.add_state('schema_enabled_state', status: 'pending', metadata: { age: 25 })
        end.to raise_error(ActiveRecord::RecordInvalid, /did not contain a required property of 'name'/)

        # Valid metadata
        state = user.add_state('schema_enabled_state', status: 'pending', metadata: { name: 'John Doe', age: 25 })

        expect(state).to be_valid
        expect(state.persisted?).to be true
      end
    end

    context 'with no schema defined' do
      it 'accepts any metadata for state types without a schema' do
        state = user.add_state('no_schema_state', status: 'active', metadata: {
                                 anything: 'goes',
                                 nested: {
                                   data: 'is fine too'
                                 },
                                 numbers: [1, 2, 3]
                               })

        expect(state).to be_valid
        expect(state.persisted?).to be true
      end
    end
  end
end
