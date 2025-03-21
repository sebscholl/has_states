class CreateHasStatesStates < ActiveRecord::Migration[8.0]
  def change
    create_table :has_states_states do |t|
      t.string :type, null: false
      t.string :state_type
      t.string :status, null: false

      t.json :metadata, null: false, default: {}

      t.references :stateable, polymorphic: true, null: false

      t.timestamps

      t.index %i[type stateable_id]
      t.index %i[stateable_type stateable_id]
    end
  end
end
