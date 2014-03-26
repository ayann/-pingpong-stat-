class CreateParties < ActiveRecord::Migration
  def change
    create_table :parties do |t|
      t.references :player_1, index: true
      t.references :player_2, index: true
      t.integer :score_1
      t.integer :score_2

      t.timestamps
    end
  end
end
