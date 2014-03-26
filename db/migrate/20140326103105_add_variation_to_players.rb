class AddVariationToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :variation, :integer
  end
end
