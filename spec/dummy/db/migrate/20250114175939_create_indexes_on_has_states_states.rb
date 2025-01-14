class CreateIndexesOnHasStatesStates < ActiveRecord::Migration[8.0]
  def change
    change_table :has_states_states do |t|
      t.index %i[stateable_id state_type]
      t.index %i[stateable_id state_type status]
      t.index %i[stateable_id state_type created_at]    
      t.index %i[stateable_id state_type status created_at] 
    end
  end
end