# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_12_23_212128) do
  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "has_states_states", force: :cascade do |t|
    t.string "type", null: false
    t.string "state_type"
    t.string "status", null: false
    t.json "metadata", default: {}, null: false
    t.string "stateable_type", null: false
    t.integer "stateable_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stateable_type", "stateable_id"], name: "index_has_states_states_on_stateable"
    t.index ["stateable_type", "stateable_id"], name: "index_has_states_states_on_stateable_type_and_stateable_id"
    t.index ["type", "stateable_id"], name: "index_has_states_states_on_type_and_stateable_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
