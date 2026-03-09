class Contractdetail < ApplicationRecord
  belongs_to :contract
  has_many :uctokens, dependent: :destroy
end
