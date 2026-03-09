class Contract < ApplicationRecord
  belongs_to :user, optional: true
  has_many :condocs
  has_many :condocs, dependent: :destroy
  has_many :contractdetail, dependent: :destroy
  has_many :mediafiles, through: :condocs
end
