class Archive < ApplicationRecord
  belongs_to :user, optional: true
  has_many :ardocs
  has_many :ardocs, dependent: :destroy
  has_many :mediafiles, through: :ardocs
end
