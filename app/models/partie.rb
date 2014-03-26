class Partie < ActiveRecord::Base
  belongs_to :player
  validates_presence_of :player_1_id, :player_2_id , :score_1, :score_2
  validates :score_1, :score_2, numericality: { only_integer: true }
end
