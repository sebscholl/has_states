class CreateHasStatesTables < ActiveRecord::Migration[7.1]
  def change
    create_table :has_states_states do |t|
      t.string :state_type
      t.string :status, null: false

      t.json :metadata, null: false, default: {}

      t.references :stateable, polymorphic: true, null: false

      t.datetime :completed_at
      t.timestamps

      t.index [ :stateable_type, :stateable_id ]
    end
  end
end
