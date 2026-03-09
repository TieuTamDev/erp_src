class Address < ApplicationRecord
  belongs_to :user
  belongs_to :mediafile
  has_many :adddocs
  has_many :adddocs, dependent: :destroy
  has_many :mediafiles, through: :adddocs
end
