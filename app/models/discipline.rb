class Discipline < ApplicationRecord
  belongs_to :user, optional: true
  has_many :discdocs
  has_many :discdocs, dependent: :destroy
  has_many :mediafiles, through: :discdocs
end
