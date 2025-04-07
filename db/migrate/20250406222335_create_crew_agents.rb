class CreateCrewAgents < ActiveRecord::Migration[7.0]
  def change
    create_table :crew_agents do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.string :name, null: false
      t.text :role, null: false
      t.text :goal, null: false
      t.text :backstory, null: false
      t.boolean :active, default: true
      t.timestamps
      
      t.index [:chat_room_id, :name], unique: true
    end
  end
end