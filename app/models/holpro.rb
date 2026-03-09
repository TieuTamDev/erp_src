class Holpro < ApplicationRecord
  belongs_to :holtemp
  has_many :mandocs, foreign_key: :holpros_id, dependent: :destroy
  has_many :holprosdetails, foreign_key: :holpros_id, dependent: :destroy
  belongs_to :holiday
end
