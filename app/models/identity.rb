class Identity < ApplicationRecord
  belongs_to :user, optional: true
  has_many :idendocs
  has_many :idendocs, dependent: :destroy
  has_many :mediafiles, through: :idendocs
  
end
