class Attend < ApplicationRecord
  belongs_to :user
  belongs_to :shiftselection
  has_many :attenddetails, foreign_key: :attend_id, dependent: :destroy
end
