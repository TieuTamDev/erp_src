class Benefit < ApplicationRecord
  belongs_to :user, optional: true
  has_many :bedocs
  has_many :mediafiles, through: :bedocs
  has_many :bedocs, dependent: :destroy
  
end
