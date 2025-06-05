# frozen_string_literal: true

class CreateMetaStatesStates < ActiveRecord::Migration[8.0]
  def change
    create_table :meta_states_states do |t|
      t.string :state_type
      t.string :status, null: false

      t.json :metadata, null: false, default: {}

      t.references :stateable, polymorphic: true, null: false

      t.datetime :completed_at
      t.timestamps

      t.index [:status]
      t.index %i[stateable_type stateable_id]
    end
  end
end
