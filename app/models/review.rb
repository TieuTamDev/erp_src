class Review < ApplicationRecord
  belongs_to :user, optional: true
  has_many :revdocs
  has_many :mediafiles, through: :revdocs
  has_many :revdocs, dependent: :destroy


end
