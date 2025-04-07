# frozen_string_literal: true

class CreateCrewTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :crew_tasks do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.references :crew_agent, foreign_key: true
      t.references :chat_room, null: false, foreign_key: true
      t.boolean :active, default: true
      t.jsonb :config, default: {}

      t.timestamps
    end

    add_index :crew_tasks, :name
  end
end