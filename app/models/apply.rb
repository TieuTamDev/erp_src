class Apply < ApplicationRecord
  belongs_to :user
  belongs_to :school
  belongs_to :company
  has_many :adocs
  has_many :mediafiles, through: :adocs
  has_many :adoc, dependent: :destroy
  has_many :school, dependent: :destroy
  has_many :company, dependent: :destroy 
  has_many :relative, dependent: :destroy 
end
