class Relative < ApplicationRecord
  belongs_to :apply
  has_many :reldocs, dependent: :destroy
end
