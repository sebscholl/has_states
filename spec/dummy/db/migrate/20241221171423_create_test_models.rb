# frozen_string_literal: true

class CreateTestModels < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.timestamps
    end

    create_table :companies do |t|
      t.string :name
      t.timestamps
    end
  end
end
